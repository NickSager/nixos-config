# Agent-agnostic skills — one shared skill root for every coding agent.
#
# The root lives in the shared vault: ~/Documents/Notes/.agents/skills.
# Custom skills whose names do not collide with pinned inputs remain plain
# vault files. Each agent's skills directory is ONE symlink to the root.
# Adding an agent = one entry in `agentSkillsDirs`.
#
# Pstack and Pocock install from separate pinned inputs and keep separate
# manifests. Changed files are updated in place on activation.
# Non-colliding custom sibling skills remain user-owned.

{ lib, pkgs, pstack ? null, pocock ? null, ... }:

let
  mindIntegration = pkgs.callPackage ./mind-agent-integration.nix { };
  tddAddon = ./config/skills/pocock-tdd-addon.md;
  noCommentsAddon = ./config/skills/no-comments-addon.md;
  potetoModeAddon = ./config/skills/poteto-mode-addon.md;
  repoSkills = [
    { name = "comment-sicko"; source = ./config/skills/comment-sicko; }
  ];

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
      map (sourceName:
        let
          name = if sourceName == "teach" then "build-course" else sourceName;
          upstream = "${pocock}/skills/${category}/${sourceName}";
          source =
            if sourceName == "teach" then
              pkgs.runCommand "pocock-build-course-skill" { } ''
                cp -R ${upstream} "$out"
                chmod -R u+w "$out"
                substituteInPlace "$out/SKILL.md" \
                  --replace-fail 'name: teach' 'name: build-course' \
                  --replace-fail 'description: Teach the user a new skill or concept, within this workspace.' \
                    'description: Build a persistent course workspace with missions, lessons, references, and learning records.'
              ''
            else if sourceName == "tdd" then
              pkgs.runCommand "pocock-tdd-skill" { } ''
                cp -R ${upstream} "$out"
                chmod -R u+w "$out"
                cat ${tddAddon} >> "$out/SKILL.md"
              ''
            else
              upstream;
        in {
          inherit name source sourceName;
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
  pstackSkillSource = name:
    if name == "no-comments" then
      pkgs.runCommand "pstack-no-comments-skill" { } ''
        cp -R ${pstack}/pstack/skills/${name} "$out"
        chmod -R u+w "$out"
        cat ${noCommentsAddon} >> "$out/SKILL.md"
      ''
    else if name == "poteto-mode" then
      pkgs.runCommand "pstack-poteto-mode-skill" { } ''
        cp -R ${pstack}/pstack/skills/${name} "$out"
        chmod -R u+w "$out"
        cat ${potetoModeAddon} >> "$out/SKILL.md"
      ''
    else
      "${pstack}/pstack/skills/${name}";
  pstackAgents = [ "comment-sicko.md" "poteto-agent.md" ];

  removeStaleManagedPaths = manifest: nextManifest: ''
    if [ -f "${manifest}" ]; then
      cat "${manifest}" >> "$MIND_DIR/.obsidian-mind-stage-paths"
      while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        grep -Fqx "$rel" "${nextManifest}" && continue
        ${mindIntegration}/bin/mind-agent-integration validate-managed-path \
          "$MIND_DIR" "$rel"
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
    NEXT_PSTACK_MANIFEST="$(mktemp)"
    {
      ${lib.concatMapStringsSep "\n" (s: ''printf '%s\n' '.agents/skills/${s}' '') pstackSkills}
      ${lib.concatMapStringsSep "\n" (a: ''printf '%s\n' '.claude/agents/${a}' '') pstackAgents}
    } > "$NEXT_PSTACK_MANIFEST"
    ${removeStaleManagedPaths "$PSTACK_MANIFEST" "$NEXT_PSTACK_MANIFEST"}
    mkdir -p "$MIND_DIR/.claude/agents"
    ${lib.concatMapStringsSep "\n" (s: ''
      ${mindIntegration}/bin/mind-agent-integration sync-tree-if-changed \
        ${pstackSkillSource s} "$MIND_DIR/.agents/skills/${s}"
    '') pstackSkills}
    ${lib.concatMapStringsSep "\n" (a: ''
      ${mindIntegration}/bin/mind-agent-integration install-if-changed \
        ${pstack}/pstack/agents/${a} "$MIND_DIR/.claude/agents/${a}"
    '') pstackAgents}
    ${mindIntegration}/bin/mind-agent-integration install-if-changed \
      "$NEXT_PSTACK_MANIFEST" "$PSTACK_MANIFEST"
    rm -f "$NEXT_PSTACK_MANIFEST"
    cat "$PSTACK_MANIFEST" >> "$MIND_DIR/.obsidian-mind-stage-paths"
    printf '%s\n' '.pstack-managed-files' >> "$MIND_DIR/.obsidian-mind-stage-paths"
  '';

  installPocock = ''
    POCOCK_MANIFEST="$MIND_DIR/.pocock-managed-files"
    NEXT_POCOCK_MANIFEST="$(mktemp)"
    {
      ${lib.concatMapStringsSep "\n" (skill: ''printf '%s\n' '.agents/skills/${skill.name}' '') pocockSkills}
    } > "$NEXT_POCOCK_MANIFEST"
    ${removeStaleManagedPaths "$POCOCK_MANIFEST" "$NEXT_POCOCK_MANIFEST"}
    ${lib.concatMapStringsSep "\n" (skill: ''
      ${mindIntegration}/bin/mind-agent-integration sync-tree-if-changed \
        ${skill.source} "$MIND_DIR/.agents/skills/${skill.name}"
    '') pocockSkills}
    ${mindIntegration}/bin/mind-agent-integration install-if-changed \
      "$NEXT_POCOCK_MANIFEST" "$POCOCK_MANIFEST"
    rm -f "$NEXT_POCOCK_MANIFEST"
    cat "$POCOCK_MANIFEST" >> "$MIND_DIR/.obsidian-mind-stage-paths"
    printf '%s\n' '.pocock-managed-files' >> "$MIND_DIR/.obsidian-mind-stage-paths"
  '';

  installRepoSkills = ''
    REPO_SKILLS_MANIFEST="$MIND_DIR/.repo-managed-skill-files"
    NEXT_REPO_SKILLS_MANIFEST="$(mktemp)"
    {
      ${lib.concatMapStringsSep "\n" (skill: ''printf '%s\n' '.agents/skills/${skill.name}' '') repoSkills}
    } > "$NEXT_REPO_SKILLS_MANIFEST"
    ${removeStaleManagedPaths "$REPO_SKILLS_MANIFEST" "$NEXT_REPO_SKILLS_MANIFEST"}
    ${lib.concatMapStringsSep "\n" (skill: ''
      ${mindIntegration}/bin/mind-agent-integration sync-tree-if-changed \
        ${skill.source} "$MIND_DIR/.agents/skills/${skill.name}"
    '') repoSkills}
    ${mindIntegration}/bin/mind-agent-integration install-if-changed \
      "$NEXT_REPO_SKILLS_MANIFEST" "$REPO_SKILLS_MANIFEST"
    rm -f "$NEXT_REPO_SKILLS_MANIFEST"
    cat "$REPO_SKILLS_MANIFEST" >> "$MIND_DIR/.obsidian-mind-stage-paths"
    printf '%s\n' '.repo-managed-skill-files' >> "$MIND_DIR/.obsidian-mind-stage-paths"
  '';
in
{
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "agentVault" ] ''
    MIND_DIR="$HOME/Documents/Notes"
    mkdir -p "$MIND_DIR/.agents/skills"

    ${lib.concatMapStringsSep "\n" linkAgent agentSkillsDirs}

    ${installRepoSkills}
    ${lib.optionalString (pstack != null) installPstack}
    ${lib.optionalString (pocock != null) installPocock}
  '';
}
