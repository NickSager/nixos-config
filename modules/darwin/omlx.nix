{ _7zz, fetchurl, lib, stdenvNoCC }:

let
  pin = (builtins.fromJSON (builtins.readFile ../shared/pins.json)).omlx;
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "omlx";
  inherit (pin) version;

  src = fetchurl {
    url = "https://github.com/jundot/omlx/releases/download/v${finalAttrs.version}/oMLX-${finalAttrs.version}-macos26-27.dmg";
    inherit (pin) hash;
  };

  nativeBuildInputs = [ _7zz ];
  sourceRoot = ".";

  unpackPhase = ''
    7zz x -snld "$src"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec" "$out/bin"
    cp -R oMLX.app "$out/libexec/oMLX.app"
    ln -s "$out/libexec/oMLX.app/Contents/MacOS/omlx-cli" "$out/bin/omlx"

    runHook postInstall
  '';

  dontFixup = true;

  meta = {
    description = "LLM inference server optimized for Apple Silicon";
    homepage = "https://github.com/jundot/omlx";
    license = lib.licenses.asl20;
    mainProgram = "omlx";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
