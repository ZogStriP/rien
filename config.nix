{ d, i, hm, pkgs, lib, hostname, ... } : let
  username     = "zogstrip";
  name         = "Régis Hanol";
  email        = "regis@hanol.fr";
  signingKey   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO3naLkQYJ4SP6pk/ZoPWJcUW4hoOoBzy1JoO8I5lpze";
  persist      = "/persist";
  stateVersion = "25.11";
  privateDirs  = map (directory: { inherit directory; mode = "0700"; });
in {
  imports = [
    d.nixosModules.disko
    i.nixosModules.impermanence
    hm.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username} = {
    home.username = username;
    home.homeDirectory = "/home/${username}";
    home.stateVersion = stateVersion;

    home.sessionVariables = {
      RUBY_YJIT_ENABLE = 1;
    };

    gtk.enable = true;
    gtk.gtk3.extraConfig.gtk-application-prefer-dark-theme = true;

    home.packages = with pkgs; [
      curl
      dmenu
      st
      wget
    ];

    programs = {
      home-manager.enable = true;

      bash.enable = true;
      bash.profileExtra = ''
        [[ -z "$DISPLAY" && $(tty) = "/dev/tty1" ]] && exec startx > ~/.startx.log 2>&1
      '';

      bat.enable = true;

      btop = {
        enable = true;
        settings = {
          disks_filter = "/ /boot /nix /tmp/ /swap";
          proc_tree = true;
          rounded_corners = false;
          vim_keys = true;
        };
      };

      bun.enable = true;

      chromium.enable = true;

      fastfetch.enable = true;

      fd.enable = true;

      firefox.enable = true;

      gh.enable = true;
      gh.settings.git_protocol = "ssh";

      git = {
        enable = true;
        signing = {
          format = "ssh";
          signer = lib.getExe' pkgs._1password-gui "op-ssh-sign";
          signByDefault = true;
        };
        extraConfig.user = {
          name = name;
          email = email;
          signingKey = signingKey;
        };
      };

      jq.enable = true;

      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };

      ripgrep.enable = true;

      ssh.enable = true;
      ssh.matchBlocks."*" = {
        compression = true;
        identityAgent = "~/.1password/agent.sock";
      };

      uv.enable = true;
    };
  };

  # 1Password CLI & GUI
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "1password" "1password-cli" ];
  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs._1password-gui.polkitPolicyOwners = [ username ];

  # `nh os switch .` - https://github.com/nix-community/nh
  programs.nh.enable = true;

  # enable basic set of fonts
  fonts.enableDefaultPackages = true;

  # install fira-code's nerd font
  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  # ensure users can't be changed
  users.mutableUsers = false;

  # zogstrip's user account
  users.users.${username} = {
    # just a regular user
    isNormalUser = true;
    # no password
    hashedPassword = "";
    # zogstrip's groups
    extraGroups = [
      "video" # backlight
      "wheel" # sudo
    ];
  };

  # use `agetty` to autologin
  services.getty.autologinUser = username;

  # disable root by setting an impossible password hash
  users.users.root.hashedPassword = "!";

  # dont' ask for password when `sudo`-ing
  security.sudo.wheelNeedsPassword = false;

  # enable RealtimeKit (required for pipewire / pulse)
  security.rtkit.enable = true;

  # Use dbus-broker, a better/faster dbus daemon (default in Arch)
  # https://archlinux.org/news/making-dbus-broker-our-default-d-bus-daemon/
  services.dbus.implementation = "broker";

  # enable fingerprint reader
  # enroll with `sudo fprintd-enroll zogstrip`
  # verify with `fprintd-verify`
  services.fprintd.enable = true;

  # enable fwupd to update SSD/UEFI firmwares - https://fwupd.org
  services.fwupd.enable = true;

  # disable power button
  services.logind.settings.Login.HandlePowerKey = "ignore";

  # enable pipewire for audio / video streams
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # tailscale
  services.tailscale.enable = true;

  # enable TLP for better power management
  services.tlp.enable = true;

  services.udev.extraHwdb = ''
    # remap CAPS lock to ESC
    evdev:atkbd:*
      KEYBOARD_KEY_3a=esc

    # disable RFKILL key (airplane mode)
    evdev:input:b0018v32ACp0006*
      KEYBOARD_KEY_100c6=reserved
  '';

  services.xserver = {
    # enable X window server
    enable = true;
    # use dwm window manager - https://dwm.suckless.org
    windowManager.dwm.enable = true;
    # use startx to ... start X (no display manager)
    displayManager.startx.enable = true;
    # generate `/etc/X11/xinit/xinitrc` script
    displayManager.startx.generateScript = true;
  };

  # allow brightness control via `xbacklight` from users in the video group
  hardware.acpilight.enable = true;

  # bluetooth
  hardware.bluetooth.enable = true;

  # update CPU's microcode
  hardware.cpu.intel.updateMicrocode = true;

  # various "open source" drivers / firmwares
  hardware.enableRedistributableFirmware = true;

  # enable hardware accelerated graphics drivers
  hardware.graphics.enable = true;

  # default timezone
  time.timeZone = "Europe/Paris";

  networking = {
    # machine's hostname
    hostName = hostname;
    # disable dhcpcd
    dhcpcd.enable = false;
    # enable networkd (DHCP)
    useNetworkd = true;
    # enable iwd (WiFi)
    wireless.iwd.enable = true;
  };

  boot = {
    # use latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # disable these kernel modules during boot (so they don't trigger errors)
    blacklistedKernelModules = [
      "cros-usbpd-charger"  # not used by frame.work EC and causes boot time error log
      "hid-sensor-hub"      # prevent interferences with fn/media keys - https://community.frame.work/t/20675/391
      "iTCO_wdt"            # disable "Intel TCO Watchdog Timer"
      "mei_wdt"             # disable "Intel Management Engine Interface Watchdog Timer"
    ];

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

  # enable in-memory compressed swap
  zramSwap.enable = true;

  # enable automatic BTRFS scrubbing
  services.btrfs.autoScrub.enable = true;

  # ensure /persist is mounted at boot
  fileSystems.${persist}.neededForBoot = true;

  # everything that needs to be persisted
  environment.persistence.${persist} = {
    hideMounts = true;

    # required system directories
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/fprint"
      "/var/lib/iwd"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/tailscale"
    ];

    # required system files
    files = [
      "/etc/machine-id"
    ];

    users.${username} = {
      # required user directories
      directories = privateDirs [
        ".cache"
        ".cargo"
        ".config/1Password"
        ".config/gh"
        ".config/op"
        ".bun"
        ".mozilla"
        ".ssh"
        "poetry"
      ];

      # required user files
      files = [
        ".bash_history"
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
              # disable workqueue for better SSD performance
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
