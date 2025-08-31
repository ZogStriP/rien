{ d, i, hm, pkgs, lib, hostname, ... } : let 
  username = "zogstrip";
  email = "regis@hanol.fr";
  stateVersion = "25.05";
in {
  imports = [ 
    d.nixosModules.disko
    i.nixosModules.impermanence
    hm.nixosModules.home-manager
  ];

  system.stateVersion = stateVersion;
}
