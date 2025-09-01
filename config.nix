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

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = stateVersion;
}
