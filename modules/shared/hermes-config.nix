{ lib, pkgs, ... }:

let
  approvalDeny = [
    "*ansible-playbook*"
    "*doas*"
    "*fly*deploy*"
    "*gh*pr create*"
    "*gh*pr merge*"
    "*git*branch -D*"
    "*git*checkout --*"
    "*git*clean*"
    "*git*push*"
    "*git*reset --hard*"
    "*git*restore*"
    "*helm*install*"
    "*helm*uninstall*"
    "*helm*upgrade*"
    "*kubectl*"
    "*netlify*deploy*"
    "*pulumi*destroy*"
    "*pulumi*up*"
    "*railway*up*"
    "*rm -rf*"
    "*sudo*"
    "*terraform*apply*"
    "*terraform*destroy*"
    "*vercel*deploy*"
  ];

  managedPolicy = pkgs.writeTextDir "config.yaml" (lib.generators.toYAML { } {
    approvals = {
      mode = "smart";
      cron_mode = "deny";
      single_query_mode = "approve";
      unattended_mode = "deny";
      denial_breaker_threshold = 3;
      deny = approvalDeny;
    };
    delegation = {
      subagent_auto_approve = true;
      worktree_isolation = true;
    };
    display = {
      interface = "tui";
      mouse_tracking = "wheel";
    };
    security = {
      tirith_enabled = true;
      tirith_path = "${pkgs.tirith}/bin/tirith";
    };
  });

in
{
  home.sessionVariables.HERMES_MANAGED_DIR = "${managedPolicy}";

  home.activation.hermesManagedPolicy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /bin/launchctl setenv HERMES_MANAGED_DIR ${managedPolicy}
  '';
}
