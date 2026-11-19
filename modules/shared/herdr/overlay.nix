# Applied after herdr.overlays.default. Herdr 0.9.5 detects Hermes only when the
# launcher's inline bootstrap matches one captured revision; every Hermes update
# or rollback regenerates it, so panes go undetected. Delete once Herdr upstream
# matches regenerated bootstraps.
#
# Fail loudly, never quietly: --fuzz=0 rejects the patch if upstream changed the
# surrounding code, and the Hermes detection tests run in the build. The upstream
# package skips tests and trims test fixtures, so build from the full source.
herdrSrc: final: prev: {
  herdr = prev.herdr.overrideAttrs (old: {
    src = herdrSrc;
    patches = (old.patches or [ ]) ++ [ ./hermes-detect.patch ];
    patchFlags = [ "-p1" "--fuzz=0" ];
    doCheck = true;
    cargoTestFlags = [ "--bin" "herdr" ];
    checkFlags = [ "detect::tests::" ];
  });
}
