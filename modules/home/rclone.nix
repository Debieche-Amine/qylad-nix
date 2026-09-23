{
  config,
  lib,
  pkgs,
  ...
}: let
  secretDir = "${config.secrets.dir}/rclone";
  qylad03TokenFile = "${secretDir}/qylad03-token";
  qylad03ClientIdFile = "${secretDir}/qylad03-client-id";
  qylad03ClientSecretFile = "${secretDir}/qylad03-client-secret";
  rvnvtrklFdfTokenFile = "${secretDir}/rvnvtrklFdf-token";

  mkMountCleanup = name: mountPoint: {
    "rclone-mount:@${name}" = {
      Service = {
        # Unmount stale or hung FUSE mount point before start and after stop
        ExecStartPre = lib.mkForce [
          "-/run/wrappers/bin/fusermount -u -z ${mountPoint}"
          "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
        ];
        ExecStopPost = [
          "-/run/wrappers/bin/fusermount -u -z ${mountPoint}"
        ];
      };
    };
  };
in {
  programs.rclone = {
    enable = true;

    remotes = {
      qylad03 = {
        config = {
          type = "drive";
          scope = "drive";
          chunk_size = "64M";
        };

        secrets = {
          token = qylad03TokenFile;
          client_id = qylad03ClientIdFile;
          client_secret = qylad03ClientSecretFile;
        };

        mounts = {
          "" = {
            enable = true;
            mountPoint = "${config.home.homeDirectory}/remote/qylad03";
            autoMount = true;
            options = {
              vfs-cache-mode = "full";
              vfs-cache-max-age = "12h";
              vfs-cache-max-size = "7G";
              dir-cache-time = "24h";
            };
          };
        };
      };

      rvnvtrklFdf = {
        config = {
          type = "drive";
          scope = "drive";
          chunk_size = "64M";
        };

        secrets = {
          token = rvnvtrklFdfTokenFile;
        };

        mounts = {
          "" = {
            enable = true;
            mountPoint = "${config.home.homeDirectory}/remote/rvnvtrklFdf";
            autoMount = true;
            options = {
              vfs-cache-mode = "full";
              vfs-cache-max-age = "12h";
              vfs-cache-max-size = "7G";
              dir-cache-time = "24h";
            };
          };
        };
      };
    };
  };

  systemd.user.services = lib.mkMerge [
    (mkMountCleanup "qylad03" "${config.home.homeDirectory}/remote/qylad03")
    (mkMountCleanup "rvnvtrklFdf" "${config.home.homeDirectory}/remote/rvnvtrklFdf")
  ];
}
