{
  lib,
  platforms,
  fetchFromGitHub,
  buildGoModule,
  versions,
}:

let
  cmd = "github.com/apernet/hysteria/app/v2/cmd";
in
buildGoModule rec {
  pname = "hysteria";
  version = versions.version;

  src = fetchFromGitHub {
    owner = "apernet";
    repo = "hysteria";
    rev = "app/v${versions.version}";
    hash = versions.hash;
  };

  vendorHash = versions.vendorHash;
  modRoot = "./app";
  env.GOWORK = "off";

  ldflags = [
    "-s"
    "-w"
  ];

  preBuild = ''
    goVersionOutput=$(go version)
    goVersionInfo=$(echo "$goVersionOutput" | sed 's/^go version //')
    goToolchain=$(echo "$goVersionInfo" | awk '{print $1}')
    goPlatform=$(echo "$goVersionInfo" | awk '{print $2}' | cut -d/ -f1)
    goArch=$(echo "$goVersionInfo" | awk '{print $2}' | cut -d/ -f2)

    ldflags="$ldflags -X '${cmd}.libVersion=${versions.libVersion}'"
    ldflags="$ldflags -X '${cmd}.appVersion=${version}'"
    ldflags="$ldflags -X '${cmd}.appDate=${versions.date}'"
    ldflags="$ldflags -X '${cmd}.appType=release'"
    ldflags="$ldflags -X '${cmd}.appCommit=${versions.rev}'"
    ldflags="$ldflags -X '${cmd}.appPlatform=$goPlatform'"
    ldflags="$ldflags -X '${cmd}.appArch=$goArch'"
    ldflags="$ldflags -X '${cmd}.appToolchain=$goToolchain'"
  '';

  patchPhase = ''
    rm app/internal/http/server_test.go \
       app/internal/sockopts/sockopts_linux_test.go \
       app/internal/socks5/server_test.go \
       app/internal/utils/certloader_test.go
  '';

  postInstall = ''
    mv $out/bin/app $out/bin/hysteria
  '';

  meta = with lib; {
    inherit platforms;
    mainProgram = "hysteria";
    description = "A powerful, lightning fast and censorship resistant proxy.";
    homepage = "https://v2.hysteria.network/";
    license = licenses.mit;
  };
}
