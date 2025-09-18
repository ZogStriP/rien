# One command && in RAM

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko#disko-install -- \
  --flake github:zogstrip/rien#framezork \
  --write-efi-boot-entries \
  --disk nvme /dev/nvme0n1
```

# Three commands && on disk

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --flake github:zogstrip/rien#framezork
sudo mount --bind /mnt/nix /nix
sudo nixos-install --flake github:zogstrip/rien#framezork
```
