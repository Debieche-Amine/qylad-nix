{pkgs, ...}: {
  services.postgresql = {
    enable = true;
    settings.port = 5432;
    # Name unified to "litellm"
    ensureDatabases = ["litellm"];
    ensureUsers = [
      {
        # Name unified to "litellm"
        name = "litellm";
        ensureDBOwnership = true;
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      # type database user address method
      local  all      all              trust
      host   all      all  127.0.0.1/32 scram-sha-256
      host   all      all  ::1/128      scram-sha-256
    '';
  };
}
