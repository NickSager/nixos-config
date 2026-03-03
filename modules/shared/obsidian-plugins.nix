# Vendored Obsidian community plugin derivations.
# Each plugin downloads main.js, manifest.json, and styles.css from the plugin's
# official GitHub release — the same files Obsidian's built-in installer fetches.
#
# To add more plugins, find the owner/repo/version/tag from the plugin's GitHub
# releases page, then compute the hash with:
#   nix hash path <(curl -sfL .../main.js; curl -sfL .../manifest.json; curl -sfL .../styles.css)
# Or look up the attr name in the full catalog:
#   https://github.com/cjavad/nixpille-obsidian-community-plugins/blob/main/plugins.nix
#
# To update a plugin, bump the version/tag and update the hash. Build will fail
# with the expected hash if you leave the old one — copy the correct hash from
# the error message.

{ pkgs }:

let
  mkPlugin =
    { owner, repo, version, tag ? version, hash }:
    let
      baseUrl = "https://github.com/${owner}/${repo}/releases/download/${tag}";
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = repo;
      inherit version;
      outputHash = hash;
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      nativeBuildInputs = [ pkgs.curl ];
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out
        curl -sfL -o $out/main.js "${baseUrl}/main.js"
        curl -sfL -o $out/manifest.json "${baseUrl}/manifest.json"
        curl -sfL -o $out/styles.css "${baseUrl}/styles.css" 2>/dev/null || true
      '';
    };
in
{
  # Essential
  obsidian-tasks-plugin = mkPlugin {
    owner = "obsidian-tasks-group";
    repo = "obsidian-tasks";
    version = "7.22.0";
    hash = "sha256-Ve33LF/aA8XjUalD8gqZ4lXMAC1TKltViZfBDqL0H6o=";
  };
  obsidian-day-planner = mkPlugin {
    owner = "ivan-lednev";
    repo = "obsidian-day-planner";
    version = "0.28.0";
    hash = "sha256-ZbGh7hlZ0YVu8mkefVqnmRzAI9OkhLTA8DjS7ZRN6AU=";
  };
  dataview = mkPlugin {
    owner = "blacksmithgu";
    repo = "obsidian-dataview";
    version = "0.5.70";
    hash = "sha256-mBXQrFHSZaqj6P9ZGzGfw1UfnQKroTlkilI/IOl7Q+g=";
  };
  templater-obsidian = mkPlugin {
    owner = "SilentVoid13";
    repo = "Templater";
    version = "2.18.1";
    hash = "sha256-xh6iQn0IXsa2gJH8360MQagpJT3M4+FrdWQGMOH5d7E=";
  };
  nldates-obsidian = mkPlugin {
    owner = "argenos";
    repo = "nldates-obsidian";
    version = "0.6.2";
    hash = "sha256-xbefGDCx7hH8onudG5S3cEGgFhd1vjXJo0jJm9t5ZyA=";
  };

  # Recommended
  markdown-table-editor = mkPlugin {
    owner = "ganesshkumar";
    repo = "obsidian-table-editor";
    version = "0.3.1";
    hash = "sha256-lqOwI973i5l95i7Ob6VM+p5clYBzMBvMfJ5tsEqar0Y=";
  };
  obsidian-plantuml = mkPlugin {
    owner = "joethei";
    repo = "obsidian-plantuml";
    version = "1.8.0";
    hash = "sha256-dGB/p8VP5u9D4QZXr3J7fPm2Mo4d3/I7qnGAeMNtfyc=";
  };
  emoji-shortcodes = mkPlugin {
    owner = "phibr0";
    repo = "obsidian-emoji-shortcodes";
    version = "2.2.0";
    hash = "sha256-K7l+RBg6lOCJCGFY6NHfTPSsw/oJjEfndtnXmCIV4oc=";
  };
  obsidian-emoji-toolbar = mkPlugin {
    owner = "oliveryh";
    repo = "obsidian-emoji-toolbar";
    version = "1.0.0";
    hash = "sha256-q9GeQ+5rVTiLHWTau1U+UPIi0JTV6nqSqlwvicQg13U=";
  };

  # Optional
  obsidian-style-settings = mkPlugin {
    owner = "mgmeyers";
    repo = "obsidian-style-settings";
    version = "1.0.9";
    hash = "sha256-oJ65ABQshqa0MO6JJ68VvUehRictlGVq3INteOJKN+s=";
  };
  obsidian-mindmap-nextgen = mkPlugin {
    owner = "james-tindal";
    repo = "obsidian-mindmap-nextgen";
    version = "1.15.1";
    hash = "sha256-5agWf0bLAf6Np5a6BQ88QOcsbXqcj+3Sdv0QlaXMgfY=";
  };
  marp-slides = mkPlugin {
    owner = "samuele-cozzi";
    repo = "obsidian-marp-slides";
    version = "0.45.6";
    hash = "sha256-4ubqS0hVRzIyqYgrCqaRsbHQpTKZPjj0rVGJEabD+b0=";
  };
  obsidian-image-toolkit = mkPlugin {
    owner = "obsidian-community";
    repo = "obsidian-image-toolkit";
    version = "0.2.0";
    hash = "sha256-fTBB+sHRECO7FbC8pc+wsIJ5pt8uxtXASR4ZOqYjn3o=";
  };
  simple-time-tracker = mkPlugin {
    owner = "Ellpeck";
    repo = "ObsidianSimpleTimeTracker";
    version = "1.2.2";
    hash = "sha256-vcvDkWAxB4lEqgRXJD/qJpqgNaeMAoS0tF0nFFXOGtk=";
  };
  vim-yank-highlight = mkPlugin {
    owner = "aleksey-rowan";
    repo = "obsidian-vim-yank-highlight";
    version = "1.0.8";
    hash = "sha256-K36V3jDSqG5VBHLiEjkkNi3CllH1/fA5tmEm0mrtvzc=";
  };
}
