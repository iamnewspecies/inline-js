{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import haskellNix.sources.nixpkgs-unstable haskellNix.nixpkgsArgs
, pkgsVanilla ? import haskellNix.sources.nixpkgs-unstable { }
}:
pkgsVanilla.callPackage
  ({ nodePackages, nodejs-14_x, stdenvNoCC }:
    let
      src = pkgs.haskell-nix.haskellLib.cleanGit {
        name = "inline-js-parser-src";
        src = ../.;
        subDir = "inline-js-parser";
      };
      src_configured = stdenvNoCC.mkDerivation {
        name = "inline-js-parser-src-configured";
        inherit src;
        nativeBuildInputs = [ nodePackages.node2nix ];
        buildPhase = "node2nix -l package-lock.json -d -14";
        installPhase = "cp -R ./ $out";
      };
      node_dependencies =
        (import src_configured { pkgs = pkgsVanilla; }).nodeDependencies;
      jsbits = stdenvNoCC.mkDerivation {
        name = "inline-js-jsbits";
        inherit src;
        nativeBuildInputs = [ nodejs-14_x ];
        buildPhase = ''
          ln -s ${node_dependencies}/lib/node_modules
          npm run-script build
        '';
        installPhase = "mv dist/main.js $out";
        allowedReferences = [ ];
      };
    in
    jsbits)
{ }
