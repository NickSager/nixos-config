{ coreutils
, findutils
, gawk
, git
, gnugrep
, gnupatch
, gnused
, writeShellApplication
}:

writeShellApplication {
  name = "mind-agent-integration";
  runtimeInputs = [
    coreutils
    findutils
    gawk
    git
    gnugrep
    gnupatch
    gnused
  ];
  text = builtins.readFile ./scripts/mind-agent-integration.sh;
}
