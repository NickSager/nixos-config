# Agent-agnostic skills — one shared skill root for every coding agent.
#
# The root lives in the agent vault: ~/Documents/Mind/.agents/skills.
# Custom skills are plain vault files (never nix-managed, so agents can
# edit them in place); each agent's skills directory is ONE symlink to
# the root. Adding an agent = one entry in `agentSkillsDirs`.

{ lib, ... }:

let
  # Every agent's skills path becomes a single symlink to the shared root.
  agentSkillsDirs = [
    "$HOME/.claude/skills"
  ];

  # If an agent's skills path is a real directory (pre-existing install),
  # rescue anything unmanaged into the shared root, then replace it with
  # the symlink. ln -sfn does NOT replace a real directory (it would create
  # a link INSIDE it), so the rm is required; guarded on -d && ! -L it is
  # a no-op once the link exists.
  linkAgent = dir: ''
    if [ -d "${dir}" ] && [ ! -L "${dir}" ]; then
      cp -Rn "${dir}"/* "$MIND_DIR/.agents/skills/" 2>/dev/null || true
      rm -rf "${dir}"
    fi
    ln -sfn "$MIND_DIR/.agents/skills" "${dir}"
  '';
in
{
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MIND_DIR="$HOME/Documents/Mind"
    mkdir -p "$MIND_DIR/.agents/skills"

    ${lib.concatMapStringsSep "\n" linkAgent agentSkillsDirs}
  '';
}
