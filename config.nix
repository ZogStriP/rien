{ d, i, hm, pkgs, hostname, ... } : let 
  username     = "zogstrip";
  name         = "Régis Hanol";
  email        = "regis@hanol.fr";
  persist      = "/persist";
  stateVersion = "25.05";
in {
  imports = [
    d.nixosModules.disko
    i.nixosModules.impermanence
    hm.nixosModules.home-manager
  ];

  # ensure users can't be changed
  users.mutableUsers = false;

  # zogstrip's user account
  users.users.${username} = {
    # just a regular user
    isNormalUser = true;
    # no password
    hashedPassword = "";
    # zogstrip's groups
    extraGroups = [ "wheel" ];
  };

  # autologin as zogstrip
  services.getty.autologinUser = username;

  # disable root by setting an impossible password hash
  users.users.root.hashedPassword = "!";

  # dont' ask for password when `sudo`-ing
  security.sudo.wheelNeedsPassword = false;

  # default timezone
  time.timeZone = "Europe/Paris";

  # machine's hostname
  networking.hostName = hostname;

  boot = {
    # use latest kernerl
    kernelPackages = pkgs.linuxPackages_latest;

    # use systemd as PID 1
    initrd.systemd.enable = true;

    loader = {
      # don't display the boot loaded screen (press <space> to show if if needed)
      timeout = 0;

      systemd-boot = {
        # enable systemd-boot boot loader
        enable = true;
        # disable editing the boot menu
        editor = false;
        # keep a maximum of 5 generations
        configurationLimit = 5;
      };

      # allow NixOS to modify EFI variables
      efi.canTouchEfiVariables = true;
    };
  };

  # enable zram swap
  zramSwap.enable = true;

  # enable automatic BTRFS scrubbing
  services.btrfs.autoScrub.enable = true;

  # ensure /persist is mounted at boot
  fileSystems.${persist}.neededForBoot = true;

  # everything that needs to be persisted
  environment.persistence.${persist} = {
    hideMounts = true;

    files = [
      "/etc/machine-id"
    ];

    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
    ];
  };

  # disk layout / partitions
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
              # allows TRIM through LUKS
              settings.allowDiscards = true;
              # disable workqueue for increased SSD performance
              settings.bypassWorkqueues = true;
              content = {
                type = "btrfs";
                subvolumes = {
                  "@nix" = { 
                    mountpoint = "/nix"; 
                    mountOptions = [ "noatime" ];
                  };
                  "@persist" = { 
                    mountpoint = persist; 
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

  # enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # ensures members of the wheel group can talk to nix's daemon
  nix.settings.trusted-users = [ "@wheel" ];

  # this is an intel x86_64 machine
  nixpkgs.hostPlatform = "x86_64-linux";

  # used for backward compatibility
  system.stateVersion = stateVersion;
}
