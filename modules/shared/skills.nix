# Agent-agnostic skills — one shared skill root for every coding agent.
#
# The root lives in the agent vault: ~/Documents/Mind/.agents/skills.
# Custom skills are plain vault files (never nix-managed, so agents can
# edit them in place); each agent's skills directory is ONE symlink to
# the root. Adding an agent = one entry in `agentSkillsDirs`.
#
# The pstack set (flake input, pinned commit) installs into the same root
# behind the potetoSkills switch. Skill directories and the 2 agent files
# are overwritten from the pin on every rebuild; local edits to them do
# not survive a switch. Off removes exactly the pinned set's names.

{ lib, pstack ? null, ... }:

let
  # Disable switch for the whole pstack set (including unslop).
  potetoSkills = true;

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
      cp -Rn "${dir}"/. "$MIND_DIR/.agents/skills/" 2>/dev/null || true
      rm -rf "${dir}"
    fi
    ln -sfn "$MIND_DIR/.agents/skills" "${dir}"
  '';

  # Skill names come from the pinned source, so the off branch removes
  # exactly what the on branch installed and touches nothing else.
  pstackSkills =
    if pstack != null
    then builtins.attrNames (builtins.readDir "${pstack}/pstack/skills")
    else [];
  pstackAgents = [ "comment-sicko.md" "poteto-agent.md" ];

  installPstack = ''
    mkdir -p "$MIND_DIR/.claude/agents"
    ${lib.concatMapStringsSep "\n" (s: ''
      chmod -R u+w "$MIND_DIR/.agents/skills/${s}" 2>/dev/null || true
      rm -rf "$MIND_DIR/.agents/skills/${s}"
      cp -R ${pstack}/pstack/skills/${s} "$MIND_DIR/.agents/skills/${s}"
    '') pstackSkills}
    ${lib.concatMapStringsSep "\n" (a: ''
      install -m644 ${pstack}/pstack/agents/${a} "$MIND_DIR/.claude/agents/${a}"
    '') pstackAgents}
    chmod -R u+w "$MIND_DIR/.agents/skills"
  '';

  removePstack = ''
    ${lib.concatMapStringsSep "\n" (s: ''
      chmod -R u+w "$MIND_DIR/.agents/skills/${s}" 2>/dev/null || true
      rm -rf "$MIND_DIR/.agents/skills/${s}"
    '') pstackSkills}
    ${lib.concatMapStringsSep "\n" (a: ''
      rm -f "$MIND_DIR/.claude/agents/${a}"
    '') pstackAgents}
  '';
in
{
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MIND_DIR="$HOME/Documents/Mind"
    mkdir -p "$MIND_DIR/.agents/skills"

    ${lib.concatMapStringsSep "\n" linkAgent agentSkillsDirs}

    ${lib.optionalString (pstack != null)
      (if potetoSkills then installPstack else removePstack)}
  '';
}
