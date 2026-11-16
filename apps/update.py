"""Refresh every pinned input: flake.lock, the Herdr tag, and modules/shared/pins.json.

Run from the repository root through `nix run .#update`. Each source moves to its
latest stable upstream release. obsidian-mind is only reported, because a new
release migrates the vault and needs a read of its changelog first.
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


def latest_tag(repo):
    # Upstreams publish rc, dev, and preview builds as ordinary releases, so
    # GitHub's "latest" and prerelease flags can't be trusted to mean stable.
    releases = json.loads(fetch(f"https://api.github.com/repos/{repo}/releases"))
    return next(
        r["tag_name"]
        for r in releases
        if not (r["draft"] or r["prerelease"]) and STABLE_TAG.fullmatch(r["tag_name"])
    )


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


def update_herdr():
    text = FLAKE.read_text()
    pattern = r'(url = "github:herdrdev/herdr/)([^"]+)(")'
    old = re.search(pattern, text).group(2)
    tag = latest_tag("herdrdev/herdr")
    if tag == old:
        return None
    FLAKE.write_text(re.sub(pattern, rf"\g<1>{tag}\g<3>", text))
    return f"herdr {old} -> {tag}"


def check_obsidian_mind():
    current = re.search(r'github:breferrari/obsidian-mind/([^"]+)"', FLAKE.read_text()).group(1)
    latest = latest_tag("breferrari/obsidian-mind")
    if latest != current:
        return f"obsidian-mind {current} -> {latest} is available; follow docs/MAINTENANCE.md"
    return None


def main():
    if not (FLAKE.exists() and PINS.exists()):
        sys.exit("Run from the nixos-config repository root.")

    pins = json.loads(PINS.read_text())
    changes = [update_herdr()]
    token = github_token()
    access = ["--option", "access-tokens", f"github.com={token}"] if token else []
    subprocess.run(["nix", "flake", "update", *access], check=True)
    changes.append(update_omlx(pins["omlx"]))
    changes.append(update_qmd(pins["qmd"]))
    changes += [update_plugin(n, p) for n, p in pins["obsidianPlugins"].items()]
    PINS.write_text(json.dumps(pins, indent=2) + "\n")

    print("\nPinned sources:")
    for line in filter(None, changes):
        print(f"  {line}")
    if not any(changes):
        print("  all current")
    notice = check_obsidian_mind()
    if notice:
        print(f"\nManual: {notice}")
    print("\nReview `git diff flake.lock modules/shared`, then run `nix run .#build`.")


if __name__ == "__main__":
    main()
