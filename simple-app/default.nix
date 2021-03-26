# Basic pinning of nixpkgs:
# - Find a commit you like (I take my nixos head so I at least start off sharing
#   most libraries with the base system).
# - Stick the commit hash here. Run nix-build to get the sha256 mismatch and put
#   the right one here. (Note that you should make the sha256 wrong first, or
#   replace it with lib.fakeSha256, or nix will use the old file.)
# - Update every so often, as makes sense for your project.
# This uses a sha256 so it gets cached longer than an hour.
{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/d4189f68fdbe0b14b7637447cb0efde2711f4abf.tar.gz";
    sha256 = "1k9x7z4a8xsmcywwpm7jbgnzrrg0b97ygwjk2adc4jhk9c0ljdny"; # nixos-20.09 @ 2021-02-22
  }) {} }:
rec {
  # Put this here so it can be used by shell.nix:
  inherit pkgs;

  # In this case, I'm building a one-file Go program with mkDerivation instead
  # of the more specialized Go builders to keep thing simple, and so it's easy
  # to change to another language/build system. You can wrap any typical build
  # steps this way.
  # Run "nix-build -A app" to build just the app.
  app = pkgs.stdenv.mkDerivation {
    pname = "app";
    version = "current";
    src = pkgs.lib.cleanSource ./.;
    nativeBuildInputs = with pkgs; [
      removeReferencesTo
    ];
    buildInputs = with pkgs; [
      go
    ];
    buildPhase = ''
      export GOCACHE=/tmp  # avoid using HOME
      go build -o $out/app .
    '';
    # Replicate what the specialized Go builders do:
    fixupPhase = "remove-references-to -t ${pkgs.go} $out/event_logger";
    # The build output directly to $out, so nothing here:
    installPhase = ":";
  };

  # Bundle the app into a docker image.
  # Run "$(nix-build -A docker) | docker load" to load the docker image into docker.
  docker = pkgs.dockerTools.streamLayeredImage {
    name = "app";
    config = {
      User = "1000:1000";
      Cmd = [ "${app}/app" ];
    };
  };
}
