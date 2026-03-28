{
  description = "Brightworker desktop app (pre-built binary)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        version = "0.0.1";

        platformMap = {
          "x86_64-linux" = "x86_64-linux";
        };
        platform = platformMap.${system} or (throw "Unsupported system: ${system}");

        binary = pkgs.fetchurl {
          url = "https://github.com/brightworks/brightworker-release/releases/download/v${version}/brightworker-${platform}";
          sha256 = pkgs.lib.fakeHash;
        };

        runtimeLibs = with pkgs; [
          gtk3
          webkitgtk_4_1
          libsoup_3
          openssl
          librsvg
          libappindicator-gtk3
          glib
          glib-networking
        ];
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "brightworker";
          inherit version;

          src = binary;
          dontUnpack = true;

          nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
          buildInputs = runtimeLibs;

          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/brightworker
            chmod +x $out/bin/brightworker
          '';

          postFixup = ''
            wrapProgram $out/bin/brightworker \
              --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}" \
              --set GIO_EXTRA_MODULES "${pkgs.glib-networking}/lib/gio/modules"
          '';

          meta = {
            description = "Brightworker - Glints runtime + Brightworks agent";
            platforms = builtins.attrNames platformMap;
          };
        };
      });
}
