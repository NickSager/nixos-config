{ coreutils
, findutils
, gawk
, git
, gnugrep
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
    gnused
  ];
  text = builtins.readFile ./scripts/mind-agent-integration.sh;
}
