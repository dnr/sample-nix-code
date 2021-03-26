# Specific config for nuc

{ config, pkgs, ... }:

let
  btrfsCmp = "compress-force=zstd:1";
  const = import ./const.nix;
in
{
  imports = [
    <nixos-hardware/common/pc/ssd> # turns on fstrim
    <nixos-hardware/common/cpu/intel> # some intel microcode stuff
  ];

  # Latest kernel fixes i915 bugs and stuff
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bluetooth dongle
  hardware.firmware = [
    pkgs.broadcom-bt-firmware
  ];

  fileSystems = let
    mkRemovable = dev: {
      device = "/dev/${dev}";
      options = [ "noauto" "user" "nodev" "noexec" "nosuid" ];
    };
    mkSubvol = subvol: {
      label = "data";
      options = [ "subvol=${subvol}" "noatime" btrfsCmp ];
    };
    noauto = spec:
      spec // { options = spec.options ++ [ "noauto" ]; };
  in
  {
    "/" = {
      options = [ "noatime" btrfsCmp ]; # subvol=nixroot
    };
    "/boot/efi" = {
      label = "EFISYS";
    };
    "/var/lib/docker" =         mkSubvol "docker";
    "/home"           =         mkSubvol "home";
    "/top"            =  noauto(mkSubvol "/");

    "/mnt/otherdisk" = {
      label = "otherdisk";
      options = [ "noatime" ];
    };

    "/mnt/sdb1" = mkRemovable "sdb1";
    "/mnt/sdc1" = mkRemovable "sdc1";
    "/mnt/sdd1" = mkRemovable "sdd1";
  };

  networking.firewall.allowedTCPPorts = [
    const.nixServePort
  ];
  networking.firewall.allowedUDPPorts = [
    const.wireguardPort
  ];

  # Wireguard server:
  networking.wireguard.interfaces.wg1 = {
    ips = [ "10.28.0.1/16" ];
    listenPort = const.wireguardPort;
    privateKeyFile = "/etc/wg-keys/wg1";
    peers = [
      { publicKey = "7Z0MJDqf3BPPY5NEWThDhEvGe61D7LYgJ+g7t00GSns="; allowedIPs = [ "10.28.0.2/32" ]; } # laptop
      { publicKey = "qpR53muykL9llw7uo3RXk6170g/Ck+rA0BshvTBwqCI="; allowedIPs = [ "10.28.0.3/32" ]; } # phone
    ];
    postSetup = "iptables -A FORWARD -i wg1 -j ACCEPT; iptables -A FORWARD -o wg1 -j ACCEPT; iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE; iptables -t nat -A POSTROUTING -o macvlan-shim -j MASQUERADE";
    postShutdown = "iptables -D FORWARD -i wg1 -j ACCEPT; iptables -D FORWARD -o wg1 -j ACCEPT; iptables -t nat -D POSTROUTING -o eno1 -j MASQUERADE; iptables -t nat -D POSTROUTING -o macvlan-shim -j MASQUERADE";
  };
  systemd.services."wireguard-wg1".path = with pkgs; [ iptables ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    nut
  ];

  # Serve nix store to local network:
  services.nix-serve.enable = true;
  services.nix-serve.secretKeyFile = "/etc/nix-serve-keys/secret";
  services.nix-serve.port = const.nixServePort;

  time.timeZone = "US/Pacific";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
