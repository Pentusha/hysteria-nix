{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hysteria.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "vultr";
  networking.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 443 ];

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    # TODO: add your public key
  ];

  system.stateVersion = "24.11";
}
