{
  config,
  lib,
  pkgs,
  ...
}: {
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql_16;
  #   ensureDatabases = ["mydatabase"];
  #   authentication = pkgs.lib.mkOverride 10 ''
  #     #type database  DBuser  auth-method
  #     local all       all     trust
  #   '';
  # };
}
