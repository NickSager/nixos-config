# Self-updating terminal AI agents installed via upstream installer scripts.
#
# These tools aren't in nixpkgs (or their nixpkgs builds lag badly), and each
# ships an installer that bootstraps its own runtime and manages later updates.
# We only bootstrap each one once when its marker path is absent. Nix never
# pins or upgrades these.
#
#   hermes  — Nous Research agent; run `hermes setup` once to pick a provider.
#   claude  — Claude Code CLI (native install); auto-updates on startup.
#   codex   — OpenAI Codex CLI (native install); auto-updates on startup.
#
# All install to ~/.local/bin (on sessionPath), so they win over any nix build.

{ lib, pkgs, profile ? "personal", ... }:

let
  # Each installer bootstraps once when `marker` is missing.
  installers = [
    {
      name = "hermes";
      marker = "$HOME/.hermes/hermes-agent";
      command = "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash";
    }
    {
      name = "claude";
      marker = "$HOME/.local/share/claude";
      command = "curl -fsSL https://claude.ai/install.sh | bash";
    }
    {
      name = "codex";
      marker = "$HOME/.codex/packages/standalone/current";
      command = "curl -fsSL https://chatgpt.com/codex/install.sh | sh";
    }
  ];

  bootstrap = { name, marker, command }: ''
    if [ ! -e "${marker}" ]; then
      echo "Bootstrapping ${name}..."
      ${command}
    fi
  '';
in
{
  # Installers shell out to bare `curl` (e.g. to fetch uv); activation runs with
  # a minimal PATH, so export curl and the usual system dirs for the child bash.
  home.activation.aiAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.curl}/bin:$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
    ${lib.optionalString (profile == "work" && pkgs.stdenv.hostPlatform.isDarwin) ''
      export SSL_CERT_FILE=/etc/nix/certs/ca-bundle.pem
    ''}
    ${lib.concatMapStringsSep "\n" bootstrap installers}
  '';
}
