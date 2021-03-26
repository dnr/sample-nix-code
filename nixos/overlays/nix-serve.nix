self: super: {
  # nix-serve in nixpkgs is pretty old, use latest from git:
  nix-serve = super.nix-serve.overrideAttrs (old: {
    name = "nix-serve-git-60060efe";
    src = self.fetchFromGitHub {
      owner = "edolstra";
      repo = "nix-serve";
      rev = "60060efed98a1c51f7b96cc3bc2831b560b36cf4";
      sha256 = "13wvbx8807wfxyrkn99rpf3lywyg6wxxbi5m1rb2xjhn5906kn2d";
    };
  });
}
