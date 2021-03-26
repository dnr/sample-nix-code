let
  # Import default.nix to get the pinned nixpkgs and the app:
  def = (import ./.) {};
in
def.pkgs.mkShell {
  # Merge dependencies from server and client build so we can run both interactively:
  nativeBuildInputs = def.server.nativeBuildInputs ++ def.clientSh.nativeBuildInputs ++ [
    # We need to run vgo2nix after updating go deps:
    def.vgo2nix
  ];
  buildInputs = def.server.buildInputs ++ def.clientSh.buildInputs ++ [
  ];

  # The npmlock2nix shellHook sets up node_modules so that we can use "npm run dev" to
  # run our dev server for quick development and be assured that the dependencies will
  # be the same as what gets built in the nix build.
  shellHook = def.clientSh.shellHook;

  # Convenience so we can "go install" in the shell for quicker iteration compared to
  # "nix-build -A server"
  GOBIN = builtins.toString ./bin;
}
