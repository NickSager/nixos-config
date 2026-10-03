"""Route each delegate_task call to a model tier named by a trailing `tier:` line in task context.

The tier overrides the `delegation` config section for one call. All routing, credentials, and
reasoning effort still resolve through Hermes; the plugin only chooses the section's values.
"""

from __future__ import annotations

import contextvars
import json
import logging
import re
from pathlib import Path

import yaml

logger = logging.getLogger(__name__)

_TIER_LINE = re.compile(r"^\s*tier:\s*(\S+)\s*$", re.IGNORECASE)
_ROUTE_KEYS = ("provider", "model", "reasoning_effort")
_active_route: contextvars.ContextVar[dict | None] = contextvars.ContextVar("delegation_tier_route", default=None)


def _load_tiers() -> dict:
    return yaml.safe_load((Path(__file__).parent / "tiers.yaml").read_text())


def _resolve_tier(name: str, table: dict) -> str | None:
    key = name.strip().lower()
    if key in table["tiers"]:
        return key
    for tier, patterns in table.get("aliases", {}).items():
        if any(re.fullmatch(p, key) for p in patterns):
            return tier
    return None


def _split_tier(context: str | None) -> tuple[str | None, str | None]:
    if not context:
        return None, context
    lines = context.rstrip().splitlines()
    match = _TIER_LINE.match(lines[-1]) if lines else None
    if not match:
        return None, context
    return match.group(1), "\n".join(lines[:-1]).rstrip() or None


class _TierError(ValueError):
    pass


def _route_for(declared: str, parent_provider: str | None, table: dict) -> dict | None:
    """The route on the parent's provider, or None when that provider has no entry for the tier."""
    tier = _resolve_tier(declared, table)
    if tier is None:
        raise _TierError(f"Unknown delegation tier '{declared}'. Use one of {sorted(table['tiers'])}.")
    entry = table["tiers"][tier].get(parent_provider)
    return {"tier": tier, "provider": parent_provider, **entry} if entry else None


def _strip_tiers(args: dict) -> tuple[dict, list[str | None]]:
    if isinstance(args.get("tasks"), list):
        tasks, names = [], []
        for task in args["tasks"]:
            if not isinstance(task, dict):
                tasks.append(task)
                names.append(None)
                continue
            name, context = _split_tier(task.get("context"))
            tasks.append({**task, "context": context})
            names.append(name)
        return {**args, "tasks": tasks}, names
    name, context = _split_tier(args.get("context"))
    return {**args, "context": context}, [name]


def _error(message: str) -> str:
    return json.dumps({"error": message})


def _delegate_with_tier(tool_name: str, args: dict, next_call, **_):
    if tool_name != "delegate_task" or (args.get("action") or "spawn") != "spawn":
        return next_call(args)
    stripped, names = _strip_tiers(args)
    declared = [n for n in names if n]
    if not declared:
        return next_call(args)
    from agent.subagent_lifecycle import get_active_subagent_parent

    table = _load_tiers()
    parent_provider = getattr(get_active_subagent_parent(), "provider", None)
    try:
        routes = [_route_for(n, parent_provider, table) for n in declared]
    except _TierError as exc:
        return _error(str(exc))
    if any(r != routes[0] for r in routes) or len(declared) != len(names):
        return _error(
            "One delegate_task call runs on one model. Give every task the same `tier:` line, "
            "or split tasks into one delegate_task call per tier."
        )
    route = routes[0]
    if route is None:
        logger.info("delegation-tiering: no route on parent provider %s; inheriting", parent_provider)
        return next_call(stripped)
    logger.info("delegation-tiering: route=%s", route)
    token = _active_route.set(route)
    try:
        return next_call(stripped)
    finally:
        _active_route.reset(token)


def _install_config_overlay() -> bool:
    import tools.delegate_tool as delegate_tool

    base = getattr(delegate_tool, "_load_config", None)
    if base is None or getattr(base, "_delegation_tiering", False):
        return base is not None

    def load_config_with_tier() -> dict:
        cfg = base()
        route = _active_route.get()
        if not route:
            return cfg
        merged = {k: v for k, v in cfg.items() if k not in ("base_url", "api_key", "api_mode")}
        merged.update({k: route[k] for k in _ROUTE_KEYS if k in route})
        return merged

    load_config_with_tier._delegation_tiering = True
    delegate_tool._load_config = load_config_with_tier
    return True


def register(ctx) -> None:
    if not _install_config_overlay():
        logger.warning("delegation-tiering: tools.delegate_tool._load_config missing; plugin inactive")
        return
    ctx.register_middleware("tool_execution", _delegate_with_tier)
