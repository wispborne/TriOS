# If TriOS crashes on exit run it using nixGL or maybe figure it out
# I give up
#
# Also set GTK_THEME so it fits your theme ¯\_(ツ)_/¯
{
    description = "Starsector mod manager & toolkit";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs";

    outputs = {
        self,
        nixpkgs,
    }: let
        forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
        systems = ["x86_64-linux" "aarch64-linux"];
        version = "1.2.2";
    in {
        packages = forAllSystems (
            system: let
                pkgs = import nixpkgs {inherit system;};

                trios-release = pkgs.fetchzip {
                    url = "https://github.com/wispborne/TriOS/releases/download/${version}/TriOS-Linux.zip";
                    hash = "sha256-12ktCyWJunvYbtTNixN6qDl9OeOj4b+MmoA7kK3JN10=";
                };

                icon = pkgs.fetchurl {
                    url = "https://raw.githubusercontent.com/wispborne/TriOS/main/assets/images/telos_faction_crest.svg";
                    hash = "sha256-VZaGC0+yldComOBO4o14fX2uhpm4P60DEo3HQj0RWYE=";
                };

                runtimeLibs = with pkgs; [
                    gtk3
                    atk
                    cairo
                    curl
                    libepoxy
                    fontconfig
                    gdk-pixbuf
                    glib
                    harfbuzz
                    pango
                    stdenv.cc.cc.lib
                ];

                trios = pkgs.stdenv.mkDerivation {
                    pname = "trios";
                    inherit version;
                    src = trios-release;

                    nativeBuildInputs = [pkgs.autoPatchelfHook pkgs.makeWrapper] ++ runtimeLibs;

                    installPhase = ''
                        mkdir -p $out/{bin,share/trios}
                        cp -r * $out/share/trios

                        chmod +x $out/share/trios/data/flutter_assets/assets/linux/7zip/{arm64,x64}/7zzs

                        makeWrapper $out/share/trios/TriOS $out/bin/TriOS \
                            --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeLibs}:$out/share/trios/lib \
                            --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.zenity]}

                        mkdir -p $out/share/applications
                        cat > $out/share/applications/org.wisp.TriOS.desktop <<EOF
                        [Desktop Entry]
                        Name=TriOS
                        Exec=$out/bin/TriOS
                        Icon=trios
                        Type=Application
                        Categories=Game;Utility
                        Description=Starsector mod manager & Toolkit
                        EOF

                        mkdir -p $out/share/icons/hicolor/scalable/apps/
                        install -Dm644 ${icon} $out/share/icons/hicolor/scalable/apps/trios.svg
                    '';

                    dontStrip = true;
                };
            in {default = trios;}
        );

        apps = forAllSystems (system: {
            default = {
                type = "app";
                program = "${self.packages.${system}.default}/bin/TriOS";
            };
        });

        defaultPackage = forAllSystems (system: self.packages.${system}.default);
        defaultApp = forAllSystems (system: self.apps.${system}.default);
    };
}
