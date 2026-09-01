{ lib
, buildNpmPackage
, fetchurl
, fetchNpmDeps
, makeWrapper
, nodejs_22
}:

buildNpmPackage rec {
  pname = "qmd";
  version = "2.8.3";

  src = fetchurl {
    url = "https://registry.npmjs.org/@tobilu/qmd/-/qmd-${version}.tgz";
    hash = "sha512-zjfVwrObPB618B6x8SdhlGv/tX9OxRHsbQnr5DUtBvqPK6HGQ27lM+9/BAY5okpjrHVnW56hLyDkqoTcsrVLzA=";
  };

  sourceRoot = "package";
  npmFlags = [ "--omit=dev" ];
  dontNpmBuild = true;
  nodejs = nodejs_22;

  npmDeps = fetchNpmDeps {
    inherit pname version src sourceRoot;
    nativeBuildInputs = [ nodejs_22 ];
    postPatch = ''
      export HOME="$TMPDIR/npm-home"
      mkdir -p "$HOME"
      npm install --package-lock-only --ignore-scripts --omit=dev
    '';
    hash = "sha256-kmhC/LMkk1tDuhJMnsjhd0o/jrG7C5iBG1v2dN2uwng=";
  };

  postPatch = ''
    cp "$npmDeps/package-lock.json" ./package-lock.json
  '';

  installPhase = ''
    mkdir -p "$out/lib/qmd"
    cp -R bin dist skills package.json LICENSE CHANGELOG.md node_modules "$out/lib/qmd/"
    makeWrapper "$out/lib/qmd/bin/qmd" "$out/bin/qmd"
  '';

  meta = {
    description = "On-device hybrid search for markdown files";
    homepage = "https://github.com/tobi/qmd";
    license = lib.licenses.mit;
    mainProgram = "qmd";
    platforms = lib.platforms.unix;
  };
}
