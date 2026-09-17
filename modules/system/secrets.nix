{
  lib,
  username ? "qylad",
  ...
}: {
  options.secrets = {
    dir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${username}/shadow/stable";
      description = "Base directory for unmanaged external secret files";
    };
  };
}
