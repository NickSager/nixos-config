# Agent-agnostic skills — one shared skill root for every coding agent.
#
# The root lives in the agent vault: ~/Documents/Mind/.agents/skills.
# Custom skills are plain vault files (never nix-managed, so agents can
# edit them in place); each agent's skills directory is ONE symlink to
# the root. Adding an agent = one entry in `agentSkillsDirs`.
#
# Pstack and Pocock install from separate pinned inputs and keep separate
# manifests. Their managed directories are replaced on every activation;
# custom sibling skills remain user-owned. Pocock wins the two current name
# collisions (`tdd` and `teach`) so no path belongs to both sources.

{ lib, pstack ? null, pocock ? null, ... }:

let
  # Disable switch for the whole pstack set (including unslop).
  potetoSkills = true;

  # Every agent's skills path becomes a single symlink to the shared root.
  agentSkillsDirs = [
    "$HOME/.claude/skills"
    "$HOME/.agents/skills"  # Codex CLI's global skill discovery path
  ];

  # If an agent's skills path is a real directory (pre-existing install),
  # rescue anything unmanaged into the shared root, then replace it with
  # the symlink. ln -sfn does NOT replace a real directory (it would create
  # a link INSIDE it), so the rm is required; guarded on -d && ! -L it is
  # a no-op once the link exists.
  linkAgent = dir: ''
    mkdir -p "$(dirname "${dir}")"
    if [ -d "${dir}" ] && [ ! -L "${dir}" ]; then
      cp -Rn "${dir}"/. "$MIND_DIR/.agents/skills/" 2>/dev/null || true
      rm -rf "${dir}"
    fi
    ln -sfn "$MIND_DIR/.agents/skills" "${dir}"
  '';

  pocockCategories = [ "engineering" "in-progress" "misc" "productivity" ];
  pocockSkills =
    if pocock == null then [] else
    lib.concatMap (category:
      map (name: {
        inherit name;
        source = "${pocock}/skills/${category}/${name}";
      }) (lib.filter
        (name: builtins.pathExists "${pocock}/skills/${category}/${name}/SKILL.md")
        (builtins.attrNames (builtins.readDir "${pocock}/skills/${category}"))))
      pocockCategories;
  pocockSkillNames = map (skill: skill.name) pocockSkills;

  # Pocock owns collisions so each managed path has exactly one source.
  pstackSkills = lib.filter (name: !(builtins.elem name pocockSkillNames)) (
    if pstack != null
    then builtins.attrNames (builtins.readDir "${pstack}/pstack/skills")
    else []);
  pstackAgents = [ "comment-sicko.md" "poteto-agent.md" ];

  removeManagedPaths = manifest: ''
    if [ -f "${manifest}" ]; then
      cat "${manifest}" >> "$MIND_DIR/.obsidian-mind-stage-paths"
      while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        case "$rel" in
          .agents/skills/*|.claude/agents/*)
            chmod -R u+w "$MIND_DIR/$rel" 2>/dev/null || true
            rm -rf "$MIND_DIR/$rel"
            ;;
          *)
            echo "Refusing unexpected managed skill path: $rel" >&2
            exit 1
            ;;
        esac
      done < "${manifest}"
    fi
  '';

  installPstack = ''
    PSTACK_MANIFEST="$MIND_DIR/.pstack-managed-files"
    ${removeManagedPaths "$PSTACK_MANIFEST"}
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
    {
      ${lib.concatMapStringsSep "\n" (s: ''printf '%s\n' '.agents/skills/${s}' '') pstackSkills}
      ${lib.concatMapStringsSep "\n" (a: ''printf '%s\n' '.claude/agents/${a}' '') pstackAgents}
    } > "$PSTACK_MANIFEST"
    cat "$PSTACK_MANIFEST" >> "$MIND_DIR/.obsidian-mind-stage-paths"
    printf '%s\n' '.pstack-managed-files' >> "$MIND_DIR/.obsidian-mind-stage-paths"
  '';

  installPocock = ''
    POCOCK_MANIFEST="$MIND_DIR/.pocock-managed-files"
    ${removeManagedPaths "$POCOCK_MANIFEST"}
    ${lib.concatMapStringsSep "\n" (skill: ''
      cp -R ${skill.source} "$MIND_DIR/.agents/skills/${skill.name}"
      chmod -R u+w "$MIND_DIR/.agents/skills/${skill.name}"
    '') pocockSkills}
    {
      ${lib.concatMapStringsSep "\n" (skill: ''printf '%s\n' '.agents/skills/${skill.name}' '') pocockSkills}
    } > "$POCOCK_MANIFEST"
    cat "$POCOCK_MANIFEST" >> "$MIND_DIR/.obsidian-mind-stage-paths"
    printf '%s\n' '.pocock-managed-files' >> "$MIND_DIR/.obsidian-mind-stage-paths"
  '';
in
{
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "agentVault" ] ''
    MIND_DIR="$HOME/Documents/Mind"
    mkdir -p "$MIND_DIR/.agents/skills"

    ${lib.concatMapStringsSep "\n" linkAgent agentSkillsDirs}

    ${lib.optionalString (pstack != null && potetoSkills) installPstack}
    ${lib.optionalString (pocock != null) installPocock}
  '';
}
