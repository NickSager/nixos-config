# Vendored Obsidian community plugin derivations.
# Each plugin downloads main.js, manifest.json, and styles.css from the plugin's
# official GitHub release — the same files Obsidian's built-in installer fetches.
#
# Plugins are listed in pins.json under `obsidianPlugins`, keyed by manifest ID.
# `nix run .#update` moves each one to its latest release and refreshes the hash.
# To add a plugin, add an entry with any placeholder hash and run the update.

{ caBundle ? "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt", pkgs }:

let
  pins = (builtins.fromJSON (builtins.readFile ./pins.json)).obsidianPlugins;

  mkPlugin = manifestId: { owner, repo, tag, hash }:
    let
      baseUrl = "https://github.com/${owner}/${repo}/releases/download/${tag}";
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = repo;
      version = tag;
      outputHash = hash;
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      nativeBuildInputs = [ pkgs.curl ];
      SSL_CERT_FILE = caBundle;
      phases = [ "installPhase" ];
      passthru = { inherit manifestId; };
      installPhase = ''
        mkdir -p $out
        curl -sfL -o $out/main.js "${baseUrl}/main.js"
        curl -sfL -o $out/manifest.json "${baseUrl}/manifest.json"
        curl -sfL -o $out/styles.css "${baseUrl}/styles.css" 2>/dev/null || true
      '';
    };
in
builtins.mapAttrs mkPlugin pins
