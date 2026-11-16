"""Refresh every pinned input: flake.lock, the Herdr tag, and modules/shared/pins.json.

Run from the repository root through `nix run .#update`. Each source moves to its
latest stable upstream release. obsidian-mind moves only within its current major
version: a major release reshapes the vault, so it is reported for a manual
upgrade instead. Local obsidian-mind patches apply at build time, so a release
they no longer fit fails `nix run .#build` before anything reaches the vault.
"""

import json
import os
import re
import subprocess
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

PINS = Path("modules/shared/pins.json")
FLAKE = Path("flake.nix")
QMD_LOCK = Path("modules/shared/qmd-package-lock.json")


STABLE_TAG = re.compile(r"v?\d+(\.\d+)*")


def github_token():
    if token := os.environ.get("GITHUB_TOKEN"):
        return token
    try:
        return run("gh", "auth", "token")
    except (OSError, subprocess.CalledProcessError):
        return None


def fetch(url):
    headers = {"User-Agent": "nixos-config-update"}
    if url.startswith("https://api.github.com/") and (token := github_token()):
        headers["Authorization"] = f"Bearer {token}"
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers)) as r:
        return r.read()


def stable_tags(repo):
    # Upstreams publish rc, dev, and preview builds as ordinary releases, so
    # GitHub's "latest" and prerelease flags can't be trusted to mean stable.
    releases = json.loads(fetch(f"https://api.github.com/repos/{repo}/releases"))
    return [
        r["tag_name"]
        for r in releases
        if not (r["draft"] or r["prerelease"]) and STABLE_TAG.fullmatch(r["tag_name"])
    ]


def latest_tag(repo):
    return stable_tags(repo)[0]


def major(tag):
    return int(re.match(r"v?(\d+)", tag).group(1))


def run(*cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd, check=True, text=True, stdout=subprocess.PIPE).stdout.strip()


def prefetch(url):
    return json.loads(run("nix", "store", "prefetch-file", "--json", url))["hash"]


def update_omlx(pin):
    version = latest_tag("jundot/omlx").removeprefix("v")
    if version == pin["version"]:
        return None
    url = f"https://github.com/jundot/omlx/releases/download/v{version}/oMLX-{version}-macos26-27.dmg"
    old = pin["version"]
    pin.update(version=version, hash=prefetch(url))
    return f"omlx {old} -> {version}"


def update_qmd(pin):
    meta = json.loads(fetch("https://registry.npmjs.org/@tobilu/qmd/latest"))
    version = meta["version"]
    if version == pin["version"]:
        return None
    with tempfile.TemporaryDirectory() as work:
        tgz = Path(work, "qmd.tgz")
        tgz.write_bytes(fetch(meta["dist"]["tarball"]))
        with tarfile.open(tgz) as t:
            t.extractall(work, filter="data")
        package = Path(work, "package")
        run("npm", "install", "--package-lock-only", "--ignore-scripts", "--omit=dev", cwd=package)
        QMD_LOCK.write_text(Path(package, "package-lock.json").read_text())
    old = pin["version"]
    pin.update(
        version=version,
        hash=meta["dist"]["integrity"],
        npmDepsHash=run("prefetch-npm-deps", str(QMD_LOCK)),
    )
    return f"qmd {old} -> {version}"


def plugin_hash(owner, repo, tag):
    base = f"https://github.com/{owner}/{repo}/releases/download/{tag}"
    with tempfile.TemporaryDirectory() as out:
        for name in ("main.js", "manifest.json", "styles.css"):
            try:
                Path(out, name).write_bytes(fetch(f"{base}/{name}"))
            except urllib.error.HTTPError as e:
                if name != "styles.css" or e.code != 404:
                    raise
        return run("nix", "hash", "path", out)


def update_plugin(name, pin):
    tag = latest_tag(f"{pin['owner']}/{pin['repo']}")
    if tag == pin["tag"]:
        return None
    old = pin["tag"]
    pin.update(tag=tag, hash=plugin_hash(pin["owner"], pin["repo"], tag))
    return f"{name} {old} -> {tag}"


def flake_tag(repo):
    pattern = rf'(url = "github:{repo}/)([^"]+)(")'
    return pattern, re.search(pattern, FLAKE.read_text()).group(2)


def set_flake_tag(repo, tag):
    pattern, old = flake_tag(repo)
    if tag == old:
        return None
    FLAKE.write_text(re.sub(pattern, rf"\g<1>{tag}\g<3>", FLAKE.read_text()))
    return f"{repo.split('/')[1]} {old} -> {tag}"


def update_herdr():
    return set_flake_tag("herdrdev/herdr", latest_tag("herdrdev/herdr"))


def update_obsidian_mind():
    """Bump within the current major; return (change, manual notice)."""
    repo = "breferrari/obsidian-mind"
    _, current = flake_tag(repo)
    tags = stable_tags(repo)
    same_major = next(t for t in tags if major(t) == major(current))
    notice = None
    if major(tags[0]) > major(current):
        notice = f"obsidian-mind {tags[0]} is a major release; follow docs/MAINTENANCE.md"
    return set_flake_tag(repo, same_major), notice


def main():
    if not (FLAKE.exists() and PINS.exists()):
        sys.exit("Run from the nixos-config repository root.")

    pins = json.loads(PINS.read_text())
    mind_change, notice = update_obsidian_mind()
    changes = [update_herdr(), mind_change]
    config = [os.environ.get("NIX_CONFIG", "")]
    if token := github_token():
        # In the environment, not argv, so the token stays out of `ps`.
        config.append(f"access-tokens = github.com={token}")
    env = dict(os.environ, NIX_CONFIG="\n".join(config))
    subprocess.run(["nix", "flake", "update"], check=True, env=env)
    changes.append(update_omlx(pins["omlx"]))
    changes.append(update_qmd(pins["qmd"]))
    changes += [update_plugin(n, p) for n, p in pins["obsidianPlugins"].items()]
    PINS.write_text(json.dumps(pins, indent=2) + "\n")

    print("\nPinned sources:")
    for line in filter(None, changes):
        print(f"  {line}")
    if not any(changes):
        print("  all current")
    if notice:
        print(f"\nManual: {notice}")
    print("\nReview `git diff flake.lock modules/shared`, then run `nix run .#build`.")


if __name__ == "__main__":
    main()
