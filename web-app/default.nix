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
# Using "with pkgs" is sorta bad style, but it's okay for small projects:
with pkgs;
rec {
  # Put this here so it can be used by shell.nix:
  inherit pkgs;

  ### Prereqs:

  # Use a fork of npmlock2nix to fix some usability issues:
  mynpmlock2nixSrc = fetchFromGitHub {
    owner = "dnr";
    repo = "npmlock2nix";
    rev = "72a5e5b729f5f4a18295903adaea5ce3e060c2af";
    sha256 = "05023jq9177l7nb0zhv1drqi1lbjs2nz0s1f2iyzcv4yhyfsp1ra";
  };
  mynpmlock2nix = callPackage mynpmlock2nixSrc {};

  # Use a newer version of vgo2nix to fix some bugs:
  vgo2nixSrc = fetchFromGitHub {
    owner = "nix-community";
    repo = "vgo2nix";
    rev = "4546d8056ab09ece3d2489594627c0541b15a397";
    sha256 = "0n9pf0i5y59kiiv6dq8h8w1plaz9w6s67rqr2acqgxa45iq36mkh";
  };
  vgo2nix = callPackage vgo2nixSrc {};

  ### My app:

  # Server is build with Go:
  server = buildGoPackage rec {
    pname = "app-srv";
    version = "current";
    goPackagePath = "my-pkg-path/app";
    src = lib.sourceByRegex ./. [ "server(|/.*)" "go.(mod|sum)" ];
    goDeps = ./deps.nix;  # created by vgo2nix
  };

  # Describe the client build:
  clientProj = mynpmlock2nix.setup {
    src = lib.sourceByRegex ./. [ "client(|/.*)" "package.*" "static(|/[^/]+)" ];
    # npmlock2nix will run "npm run build" as the build phase by default.
    buildAttrs.postBuild = ''
      ( cd static/build && find -type f | sort | xargs sha1sum | sha1sum | cut -c-10 > VERSION )
    '';
    buildAttrs.installPhase = "mkdir -p $out && cp -a static $out";
  };
  clientSh = clientProj.shell;
  client = clientProj.build;

  # Simple derivation to put the config in a package. You can also list files or
  # directories directly in `contents` if you're less picky about the file layout.
  config = runCommand "appconfig" {}
      "mkdir -p $out/config && cp ${./config/prod.json} $out/config/prod.json";

  # Build docker image.
  docker = dockerTools.streamLayeredImage {
    name = "app";
    contents = [ server client config cacert ];
    config = {
      User = "1000:1000";
      Env = [
        "CONFIG=/config/prod.json"
        "ROOT=/static"  # server will serve files from here
      ];
      Cmd = [ "/bin/app" ];
    };
  };
}
