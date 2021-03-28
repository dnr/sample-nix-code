# This file has common parts that you want to share among all your NixOS machines.
# The parts that might be a little unusual are marked with NB.

{ config, pkgs, ... }:

let
  # NB: Each machine builds its own nixos system. If you want to do interesting things
  # with some machines building for others, you'll have to do fancier things here, or
  # set this from the wrapper script.
  host = builtins.getEnv "HOSTNAME";

  # NB: This points to a local clone of the main nixpkgs repo that will be essentially
  # used like a "channel" to set the version of nixpkgs/nixos.
  localNixpkgs = "/home/dnr/src/nixpkgs";

  # NB: This points to a git repo with your nixos configs (i.e. this file).
  localConfig = "/home/dnr/src/my-nixos-configs";
  localOverlays = localConfig + "/overlays";

  # Local clone of the nixos-hardware repo, to be used like a channel.
  localNixosHardware = "/home/dnr/src/nixos-hardware";
in
{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.fsIdentifier = "label";

  # NB: Put the hostname back here.
  networking.hostName = host;
  networking.networkmanager.enable = true;

  networking.useDHCP = false;

  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  # NB: Set this explicitly because nixos ignores the value of <nixpkgs-overlays> from
  # NIX_PATH. We copy a little code from nixpkgs to import files from a directory.
  nixpkgs.overlays = with builtins;
    map (n: import (localOverlays + "/" + n))
        (filter (n: match ".*\\.nix" n != null) (attrNames (readDir localOverlays)));

  nix.autoOptimiseStore = true;
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';  # needed for nix-direnv

  # NB: Replace "channels" with git clones that are more familiar to manage.
  # Set nixpkgs-overlays so that nix commands in the shell load overlays, as well as
  # nixos-rebuild.
  nix.nixPath = [
    "nixpkgs=${localNixpkgs}"
    "nixpkgs-overlays=${localOverlays}"
    "nixos-config=${localConfig}"
    "nixos-hardware=${localNixosHardware}"
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs;
  let
    pythonWithMyPkgs = python3.withPackages (pp: with pp; [
      requests
    ]);
  in
  [
    bc
    binutils-unwrapped
    borgbackup
    btrfs-progs
    compsize
    cryptsetup
    curl
    direnv
    dmenu
    dunst
    evince
    ffmpeg
    file
    gdb
    gimp
    git
    gnupg
    gocryptfs
    google-chrome
    hdparm
    libnotify
    lm_sensors
    lsof
    ltrace
    lzma
    magic-wormhole
    mercurial
    moreutils
    mplayer
    nix-direnv
    nvme-cli
    openssl
    opusTools
    pavucontrol
    psmisc
    pv
    pythonWithMyPkgs
    redshift
    ripgrep
    rsync
    smem
    socat
    sqlite
    strace
    sxiv
    sysstat
    tcpdump
    tree
    unzip
    vanilla-dmz
    vim
    wget
    wireguard
    xdotool
    xosd
    xsel
    xxd
    zip
    zstd
  ];

  environment.pathsToLink = [
    "/share/nix-direnv"  # needed for nix-direnv
  ];

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  services.openssh.enable = true;
  services.openssh.permitRootLogin = "no";
  services.openssh.forwardX11 = true;

  services.zerotierone.enable = true;

  virtualisation.docker.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;

  services.xserver.enable = true;
  services.xserver.windowManager.notion.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "ctrl:nocaps";

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    ubuntu_font_family
  ];

  services.physlock.enable = true;

  security.sudo.extraConfig = ''
    Defaults  !env_reset,!tty_tickets,timestamp_timeout=60
  '';

  # These need to be setuid-root to support "user" mounts in fstab.
  security.wrappers = {
    "mount.nfs".source = "${pkgs.nfs-utils}/bin/mount.nfs";
    "mount.nfs4".source = "${pkgs.nfs-utils}/bin/mount.nfs4";
    "umount.nfs".source = "${pkgs.nfs-utils}/bin/umount.nfs";
    "umount.nfs4".source = "${pkgs.nfs-utils}/bin/umount.nfs4";
  };

  # Main user account
  users.users.dnr = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "dialout"
      "docker"
      "networkmanager"
      "wheel"
    ];
  };

  # Disabling this makes rebuilds faster if you're messing with nixos modules.
  documentation.nixos.enable = false;
}
