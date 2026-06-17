{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.services.hysteria.server;
in
{
  services.hysteria.server = {
    enable = true;
    openFirewall = true;
    settings = {
      listen = ":443";

      acme = {
        domains = [ "your-domain.example.com" ];
        email = "admin@example.com";
        type = "http";
      };

      bandwidth = {
        up = "1 gbps";
        down = "1 gbps";
      };

      auth = {
        type = "password";
        password = "change-me";
      };

      quic = {
        initStreamReceiveWindow = 8388608;
        maxStreamReceiveWindow = 8388608;
        initConnReceiveWindow = 20971520;
        maxConnReceiveWindow = 20971520;
        maxIdleTimeout = "30s";
        maxIncomingStreams = 1024;
      };
    };
  };

  # hysteria2 uses UDP for the main listen port
  networking.firewall.allowedUDPPorts = mkIf cfg.enable [ 443 ];
}
