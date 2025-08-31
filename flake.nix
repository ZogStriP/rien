{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    
    impermanence.url = "github:nix-community/impermanence";
    
    hm.url = "github:nix-community/home-manager";
    hm.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, ... } @ inputs : {
    nixosConfigurations.framezork = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs // { hostname = "framezork"; };
      modules = [ ./config.nix ];
    };
  };
}
