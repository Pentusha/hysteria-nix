{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.services.hysteria.server;

  tlsCert = pkgs.runCommand "hysteria-selfsigned-tls" { } ''
    ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
      -keyout "$out/key.pem" \
      -out "$out/cert.pem" \
      -days 3650 -nodes \
      -subj "/CN=hysteria-server"
  '';
in
{
  services.hysteria.server = {
    enable = true;
    openFirewall = true;
    settings = {
      listen = ":443";

      tls = {
        cert = "${tlsCert}/cert.pem";
        key = "${tlsCert}/key.pem";
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

  networking.firewall.allowedUDPPorts = mkIf cfg.enable [ 443 ];
}
