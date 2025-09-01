{ d, i, hm, pkgs, lib, hostname, ... } : let 
  username     = "zogstrip";
  name         = "Régis Hanol";
  email        = "regis@hanol.fr";
  stateVersion = "25.05";
in {
  imports = [ 
    d.nixosModules.disko
    i.nixosModules.impermanence
    hm.nixosModules.home-manager
  ];

  zramSwap.enable = true;

  services.btrfs.autoScrub.enable = true;

  environment.persistence."/persist" = {
    hideMounts = true;

    files = [
      "/etc/machine-id"
    ];

    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
    ];
  };

  fileSystems."/persist".neededForBoot = true;

  disko.devices = {
    disk.nvme = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            type = "EF00";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "luks";
              settings.allowDiscards = true;
              settings.bypassWorkqueues = true;
              content = {
                type = "btrfs";
                subvolumes = {
                  "@nix" = { 
                    mountpoint = "/nix"; 
                    mountOptions = [ "noatime" ];
                  };
                  "@persist" = { 
                    mountpoint = "/persist"; 
                    mountOptions = [ "noatime" ];
                  };
                  "@log" = { 
                    mountpoint = "/var/log"; 
                    mountOptions = [ "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = { 
        fsType = "tmpfs"; 
        mountOptions = [ "size=128M" "mode=0755" ]; 
      };
      "/tmp" = { 
        fsType = "tmpfs"; 
        mountOptions = [ "size=4G" "mode=1777" ]; 
      };
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = stateVersion;
}
