```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --flake github:zogstrip/rien#framezork
sudo mount --bind /mnt/nix /nix
sudo nixos-install --flake github:zogstrip/rien#framezork
```
