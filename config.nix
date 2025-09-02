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
    extraGroups = [ "wheel" ];
  };

  # autologin as zogstrip
  services.getty.autologinUser = username;

  # disable root by setting an impossible password hash
  users.users.root.hashedPassword = "!";

  # dont' ask for password when `sudo`-ing
  security.sudo.wheelNeedsPassword = false;

  # enable RealtimeKit (required for pipewire / pulse)
  security.rtkit.enable = true;

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

  # Use dbus-broker, a better/faster dbus daemon (default in Arch)
  # https://archlinux.org/news/making-dbus-broker-our-default-d-bus-daemon/
  services.dbus.implementation = "broker";

  services.udev.extraHwdb = ''
    # remap CAPS lock to ESC
    evdev:atkbd:*
      KEYBOARD_KEY_3a=esc

    # disable RFKILL key (airplane mode)
    evdev:input:b0018v32ACp0006*
      KEYBOARD_KEY_100c6=reserved
  '';

  # allow brightness control via `xbacklight` from users in the video group
  hardware.acpilight.enable = true;

  # bluetooth
  hardware.bluetooth.enable = true;

  # various "open source" drivers / firmwares
  hardware.enableRedistributableFirmware = true;

  # update CPU's microcode
  hardware.cpu.intel.updateMicrocode = true;

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

    files = [
      "/etc/machine-id"
    ];

    directories = [
      "/var/lib/bluetooth"
      "/var/lib/fprint/${username}"
      "/var/lib/iwd"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/tailscale"
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
