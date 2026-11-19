# Applied after herdr.overlays.default. Herdr 0.9.5 detects Hermes only when the
# launcher's inline bootstrap matches one captured revision; every Hermes update
# or rollback regenerates it, so panes go undetected. Delete once Herdr upstream
# matches regenerated bootstraps.
final: prev: {
  herdr = prev.herdr.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hermes-detect.patch ];
  });
}
