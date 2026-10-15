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
    # Stage by path only: blanket staging sweeps up untracked .envrc and local notes.
    "*git*add -a*"
    "*git*add --all*"
    "*git*add -u*"
    "*git*add ."
    "*git*add . *"
    "*git*commit -a*"
    "*git*commit --all*"
    "git push"
    "git push origin"
    "git push -u origin"
    "git push --set-upstream origin"
    "*git*push*--all*"
    "*git*push*--mirror*"
    "*git*push*--force*"
    "*git*push*-f *"
    "*git*push* head"
    "*git*push* main*"
    "*git*push*+main*"
    "*git*push*:main*"
    "*git*push*refs/heads/main*"
    "*git*push*release/*"
    "*git*push*hotfix/*"
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

  # Atlassian Rovo MCP tool allowlist. Managed lists replace the user list wholesale,
  # so this is the complete set. Jira and Confluence writes are enabled; executeWrite
  # reaches write operations that are not exposed as primary tools. Destructive
  # operations (executeDestructive) stay excluded.
  atlassianTools = [
    "getAccessibleAtlassianResources"
    "atlassianUserInfo"
    "discover"
    "executeRead"
    "executeWrite"
    "search"
    "getTeamworkGraphContext"
    "getTeamworkGraphObject"
    "getLoomVideo"
    # Jira
    "getJiraIssue"
    "searchJiraIssuesUsingJql"
    "createJiraIssue"
    "editJiraIssue"
    "addCommentToJiraIssue"
    "transitionJiraIssue"
    "getTransitionsForJiraIssue"
    # Confluence
    "getConfluenceContent"
    "searchConfluence"
    "createConfluencePage"
    "updateConfluencePage"
    "createConfluenceFooterComment"
    "createConfluenceInlineComment"
  ];

  managedPolicy = pkgs.writeTextDir "config.yaml" (lib.generators.toYAML { } {
    mcp_servers.atlassian = {
      url = "https://mcp.atlassian.com/v2/mcp";
      connect_timeout = 120.0;
      auth = "oauth";
      enabled = true;
      tools.include = atlassianTools;
    };
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
      # Isolation tells every subagent to "commit your changes to your branch", which
      # committed vault notes and, after a stray `cd`, an untracked .envrc with secrets
      # to qxo-monorepo main. Commits are the parent's call, made by path.
      worktree_isolation = false;
    };
    dashboard = {
      show_token_analytics = true;
    };
    # Managed lists replace the user list wholesale, so Herdr's plugin stays listed here.
    plugins.enabled = [ "herdr-agent-state" "delegation-tiering" ];
    display = {
      interface = "tui";
      mouse_tracking = "buttons";
    };
    # Ctrl+B (the default) is Herdr's prefix and Ctrl+Space is tmux's.
    voice.record_key = "ctrl+q";
    stt.provider = "local";
    compression.threshold_tokens = 200000;
    security = {
      tirith_enabled = true;
      tirith_path = "${pkgs.tirith}/bin/tirith";
    };
  });

in
{
  home.sessionVariables.HERMES_MANAGED_DIR = "${managedPolicy}";

  home.file.".hermes/plugins/delegation-tiering".source = ./config/hermes-plugins/delegation-tiering;

  home.activation.hermesManagedPolicy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /bin/launchctl setenv HERMES_MANAGED_DIR ${managedPolicy}
  '';
}
