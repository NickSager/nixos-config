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
  vim-yank-highlight = mkPlugin {
    owner = "aleksey-rowan";
    repo = "obsidian-vim-yank-highlight";
    version = "1.0.8";
    hash = "sha256-K36V3jDSqG5VBHLiEjkkNi3CllH1/fA5tmEm0mrtvzc=";
  };
}
