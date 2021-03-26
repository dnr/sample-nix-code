# Specific config for laptop

{ config, pkgs, ... }:

let
  btrfsCmp = "compress-force=zstd:1";
  const = import ./const.nix;
in
{
  imports = [
    <nixos-hardware/common/pc/ssd> # turns on fstrim
    <nixos-hardware/lenovo/thinkpad/x1/6th-gen>
  ];

  # Latest kernel fixes i915 bugs and stuff
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # fbc causes weird display lagginess
  boot.kernelParams = [
    "i915.enable_fbc=0"
  ];

  fileSystems = let
    mkRemovable = dev: {
      device = "/dev/${dev}";
      options = [ "noauto" "user" "nodev" "noexec" "nosuid" ];
    };
  in
  {
    "/" = {
      options = [ "noatime" btrfsCmp ];
    };
    "/boot/efi" = {
      label = "EFISYS";
    };
    "/var/lib/docker" = {
      label = "nix";
      options = [ "subvol=docker" "noatime" btrfsCmp ];
    };
    "/mnt/sda1" = mkRemovable "sda1";
    "/mnt/sdb1" = mkRemovable "sdb1";
    "/mnt/sdc1" = mkRemovable "sdc1";
    "/mnt/sdd1" = mkRemovable "sdd1";
  };

  swapDevices = [{
    device = "/dev/disk/by-partuuid/34c32c62-f0ef-414a-9b66-cedbac5c8ab7";
    randomEncryption = true;
  }];

  networking.wireguard.interfaces.wg2 = {
    ips = [ "10.28.0.2/16" ];
    privateKeyFile = "/etc/wg-keys/wg2";
    peers = [ {
      publicKey = "O8HXMeyu3Kd3ER2vtNIWI4NE1W5HQQVceO39tRkxCBo=";
      allowedIPs = [ "10.28.0.0/16" ];
      endpoint = "my-dyn-dns.net:${toString const.wireguardPort}";
    } ];
  };

  # Let nuc act as local cache for laptop
  nix.binaryCachePublicKeys = [ "nuc:Tbgl2MO+JM+D7v75J76uMlKNUsev4iQnKhi6/hM+OUM=" ];
  nix.extraOptions = ''
    extra-substituters = http://nuc:${toString const.nixServePort}
  '';

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    tpacpi-bat
    signal-desktop
  ];

  services.illum.enable = true;

  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

  # pam-mount for home dir on encrypted block device:
  security.pam.mount.enable = true;
  users.users.dnr.pamMount = {
    path = "/dev/disk/by-uuid/50240030-0c4f-4879-8cc7-36ec6c0b42f8";
    options = "crypto_name=dnrhome,noatime,${btrfsCmp}";
  };

  time.timeZone = "US/Pacific";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
