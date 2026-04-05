# Install

```bash
nix-env --install --file https://github.com/j-a-sunny/nix-FDM/archive/refs/heads/main.zip
```

## Fix Autostart

```bash
sed -i 's|^Exec=.*|Exec=freedownloadmanager --hidden|' ~/.config/autostart/FDM.desktop
```
