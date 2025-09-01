```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko#disko-install -- \
  --flake github:zogstrip/rien#framezork \
  --write-efi-boot-entries \
  --disk nvme /dev/nvme0n1
```
