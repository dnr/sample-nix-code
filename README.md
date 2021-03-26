
This some sample Nix code for NixOS and small projects. It's meant to accompany
[this blog post](https://dnr.im/tech/nix-intro/). It's a stripped-down version
of what I use for some of my personal machines and projects.

This all uses classic Nix, not flakes.

### Contents

**`nixos`** NixOS configs for a handful of machines.

There are lots of examples online of very flexible and modular and complicated
NixOS configs, which are great and worth the time to understand. My own style is
to keep things as stubbornly simple as possible, to reduce cognitive overhead,
especially while learning. That means there are fewer files, but it's less
flexible. You probably don't want to clone these exactly as a base for your
configs, but feel free to take bits and pieces that make sense to you.

**`simple-app`** A derivation and shell for a small server.

This does a simple build and puts the result in a docker image. The resulting
`nix-shell` isn't too interesting, but the point is to have a template that can
easily be adapted to other small projects.

**`web-app`** A derivation and shell for a web app with a Go server and
Node-based build for the client portion.

This builds a web app with node, a server with Go, and packages them into a
docker image so that the server can serve the client files statically (as well
as serve a backend API). It's missing the project code so it won't work as
written, but you might find the structure helpful.

It depends on a small fork of
[npmlock2nix](https://github.com/tweag/npmlock2nix) that I made that refactors
things to make it easier to keep a build and a shell in sync.

