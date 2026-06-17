{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hysteria.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "nix";
  networking.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 443 ];

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPjU2l7xfiQ+ud8fY1843teAUrYhO4Hvzn7iKh/LrbyI pentusha@home"
  ];

  system.stateVersion = "24.11";
}
