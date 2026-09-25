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
      cp ${./qmd-package-lock.json} ./package-lock.json
    '';
    hash = "sha256-sz4tCZzmJDJ4yiPXA/o1Yjqu22tLDp1Jm07x+vjKmVw=";
  };

  postPatch = ''
    cp ${./qmd-package-lock.json} ./package-lock.json
  '';

  installPhase = ''
    mkdir -p "$out/lib/qmd"
    cp -R bin dist skills package.json LICENSE CHANGELOG.md node_modules "$out/lib/qmd/"
    makeWrapper "$out/lib/qmd/bin/qmd" "$out/bin/qmd"

    # obsidian-mind locates qmd's JS entry at `npm root -g`/@tobilu/qmd, the
    # layout `npm install -g` produces. Expose the same layout so the vault's
    # hooks spawn the entry directly under node instead of falling back to an
    # unquoted shell string that cannot carry a `**/*.md` mask intact.
    # NPM_CONFIG_PREFIX points npm's global root at this prefix.
    mkdir -p "$out/lib/node_modules/@tobilu"
    ln -s "$out/lib/qmd" "$out/lib/node_modules/@tobilu/qmd"
  '';

  meta = {
    description = "On-device hybrid search for markdown files";
    homepage = "https://github.com/tobi/qmd";
    license = lib.licenses.mit;
    mainProgram = "qmd";
    platforms = lib.platforms.unix;
  };
}
