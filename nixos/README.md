
This is a stripped-down copy of my personal NixOS configs, illustrating a few
tricks that I think help simplify the on-ramp for people new to Nix and NixOS.

See comments spread through the code for details. The "flow of control" is
roughly: `nx` → `default.nix` → `common.nix` → `$host.nix`, so you might want to
read in that order.

