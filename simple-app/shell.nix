let
  # Import default.nix to get the pinned nixpkgs and the app:
  def = (import ./.) {};
in
def.pkgs.mkShell {
  # Pull in all the build requirements, with anything else we want to use in the shell:
  nativeBuildInputs = def.app.nativeBuildInputs ++ [
  ];
  buildInputs = def.app.buildInputs ++ [
  ];

  # Other random stuff:
  shellHook = ''
  '';

  # Convenient for doing interactive Go builds:
  GOBIN = builtins.toString ./bin;
}
