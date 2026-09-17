{
  lib,
  config,
  osConfig ? null,
  ...
}: {
  options.secrets = {
    dir = lib.mkOption {
      type = lib.types.str;
      default =
        if osConfig != null && osConfig ? secrets && osConfig.secrets ? dir
        then osConfig.secrets.dir
        else "${config.home.homeDirectory}/shadow/stable";
      description = "Base directory for unmanaged external secret files";
    };
  };
}
