# Agent-agnostic skills — one shared skill set for every coding agent.
#
# Chain: modules/shared/config/skills/ (source of truth, no agent name)
#   → install-copied into $NOTES_DIR/.agents/skills/ (one writable copy;
#     agents may edit it in place, a rebuild clobbers it from the repo)
#   → each agent's skills directory is ONE symlink to that root.
#
# obsidian.nix installs its vault-workflow skills (om-*, obsidian-*, qmd,
# defuddle) into the same root, so all agents see one unified skill set.
# Adding an agent = one entry in `agentSkillsDirs`. Adding a skill = a
# directory under config/skills/ plus an entry in `skills`.

{ lib, ... }:

let
  skillsSource = ./config/skills;
  skills = [
    { name = "hld-author";      files = [ "SKILL.md" ]; }
    { name = "slop-review";     files = [ "SKILL.md" "check.py" ]; }
    { name = "tech-doc-author"; files = [ "SKILL.md" ]; }
  ];

  # Every agent's skills path becomes a single symlink to the shared root.
  agentSkillsDirs = [
    "$HOME/.claude/skills"
  ];

  installSkill = { name, files }: ''
    mkdir -p "$NOTES_DIR/.agents/skills/${name}"
    ${lib.concatMapStringsSep "\n" (f: ''
      install -m644 ${skillsSource}/${name}/${f} "$NOTES_DIR/.agents/skills/${name}/${f}"
    '') files}
  '';

  # If an agent's skills path is a real directory (pre-existing install),
  # rescue anything unmanaged into the shared root, then replace it with
  # the symlink. ln -sfn does NOT replace a real directory (it would create
  # a link INSIDE it), so the rm is required; guarded on -d && ! -L it is
  # a no-op once the link exists.
  linkAgent = dir: ''
    if [ -d "${dir}" ] && [ ! -L "${dir}" ]; then
      cp -Rn "${dir}"/* "$NOTES_DIR/.agents/skills/" 2>/dev/null || true
      rm -rf "${dir}"
    fi
    ln -sfn "$NOTES_DIR/.agents/skills" "${dir}"
  '';
in
{
  # Runs after obsidianVault so the vault-workflow skills are already
  # installed into .agents/skills before the old root is migrated away.
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "writeBoundary" "obsidianVault" ] ''
    NOTES_DIR="$HOME/Documents/Notes"
    mkdir -p "$NOTES_DIR/.agents/skills"

    ${lib.concatMapStringsSep "\n" installSkill skills}

    # One-time migration of the old vault skills root. Its contents are
    # nix-managed and already reinstalled into .agents/skills; cp -Rn
    # rescues anything unmanaged. Per-skill symlinks from a prior layout
    # are skipped by -n and removed with the directory.
    if [ -d "$NOTES_DIR/.claude/skills" ] && [ ! -L "$NOTES_DIR/.claude/skills" ]; then
      cp -Rn "$NOTES_DIR/.claude/skills"/* "$NOTES_DIR/.agents/skills/" 2>/dev/null || true
      rm -rf "$NOTES_DIR/.claude/skills"
    fi

    ${lib.concatMapStringsSep "\n" linkAgent agentSkillsDirs}
  '';
}
