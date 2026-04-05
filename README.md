
# Free Download Manager installation on NixOS

## Temporary Install

```bash
nix-env -i -f https://github.com/j-a-sunny/nix-FDM/archive/refs/heads/main.zip
```

## Temporary Install with autostart

```bash
nix-env -i -f https://github.com/j-a-sunny/nix-FDM/archive/refs/heads/fdm-autostart.zip
```

## or permanent install

Download the `freedownloadmanager.nix` file from the repo to your `/etc/nixos` folder or where ever you want and link it in your /etc/nixos/configuration.nix

After that add it to the environment.systemPackages

```nix
environment.systemPackages = with pkgs; [
  (pkgs.callPackage ./freedownloadmanager.nix { autoStart = true; }) # You can also configure autostart here
];
```

## Fix Autostart

```bash
sed -i 's|^Exec=.*|Exec=freedownloadmanager --hidden|' ~/.config/autostart/FDM.desktop
```
