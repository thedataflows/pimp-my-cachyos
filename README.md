# pimp-my-cachyos

Automate [CachyOS Linux](https://cachyos.org/) setup and configuration.

After running it, you should have a fully functional CachyOS Linux with all the tools and customization that I preffer :).

## Motivation

CachyOS already comes with tons of baked-in optimization. This repo aims to further set it up and provide an out of the box experience, ready to be used as daily driver.

It also takes care of many quirks and gotchas that I have found along the way.

## Software

The following is not an exaustive list, but a highlight of what will be installed and partially configured. These may change over time.

- Shell: `zsh`, `kitty` (default), `ghostty`, `oh-my-posh`, `atuin`, `zoxide`, `direnv`, `television`, `fzf`, `bat`, `exa`, `fd`, `ripgrep`, `yazi`, `mc`, `btop`, `htop`, `procs`
- Unified desktop environment, with consistend look and feel across GTK/QT applications
  - Themes: `Scratchy` and `Catppuccin` variants
  - Icons: `Qogir`, `Kora`
  - Cursors: `Bibata Modern Amber`
  - Fonts: `Roboto`, `JetBrainsMono Nerd Font`
- Secret management: `KeePassXC` (integrates with the browser, with ssh-agent and acts as a system wallet)
- Web browser: `Brave`
- Mail client: `Betterbird`
- Office suite: `ONLYOFFICE`
- Productivity: `AnyType`
- Editors: `VS Code`, `Zed`
- Gaming: `Steam`
- Windows OS compatibility: `Bottles` (most Windows games work with Proton layer, most Windows native apps work with Caffe layer)
- Virtualization: `QEMU`, `Virt-Manager`, `Looking Glass`
- Containers: `containerd`, ~~`nerdctl`, `kubectl`~~ `docker` (because nerctl does not support the tooling around it)
- Backup and recovery: `kopia` & `kopia-ui`, `syncthing` & `syncthing tray`, `rsync` & `grsync`, `snapper` & `btrfs assistant` (btrfs snapshots)

## Usage

1. Install CachyOS. I prefer the following:
   1. Bootloader: **Grub** (allows multiboot with other OS)
   2. Filesystem: **BTRFS**
      - It supports snapshots, and as Arch is a rolling release, it is a good idea to have them. `snap-pac` will automatically create snapshots before and after a package upgrade.
      - `grub-btrfs` can be used to add menu with snapshots to choose at boot, in case of system breakage.
   3. Desktop environment: **KDE Plasma**
   4. **No swap**. I normally use plenty of RAM on my machines. I would have programs OOM Killed than have the system slow down.

2. Clone this repo: `git clone https://github.com/thedataflows/pimp-my-cachyos.git && cd pimp-my-cachyos`

   - Install mise: `curl https://mise.run | sh` (if not already installed)
   - Show all available tasks: `mise tasks` or `mr` (alias)
   - Run all setup: `mise run all` or `mr all`
   - Individual tasks can be run as well: `mr packages:add`, `mr system:grub`, etc.

3. Reboot the system at least after the first run.

## Secrets management

I decided to use KeePassXC as a password manager, because it is portable, has a good browser integration, and can act as a system wallet replacing KDE Wallet and GNOME Keyring.

> [!WARNING]
> This repo will disable Kwallet

- <https://wiki.archlinux.org/title/KeePass#Autostart>
- <https://code.visualstudio.com/docs/editor/settings-sync#_other-linux-desktop-environments>

## Desktop Experience

### KDE Plasma (default)

I liked the look and feel of modern Gnome, but I wanted more control over the desktop. Also, some of the most used apps are QT (KDE is built with QT) and had to do some customization specifically for them.

So I decided to give KDE Plasma a go. I was surprised by how smooth it runs and how easy it was to customize the desktop the way I wanted it:

- Hidden top panels and bottom bar because I use an OLED screen.
- `Scratchy` global theme with Bibata Modern Amber cursor.
- Tray icons out of the box
- Better HiDPI support with fractional scaling (much needed when using a 4K screen), especially with Plasma 6.3.
- Better and richer apps compared to Gnome (System Settings, System Monitor, KRunner, Dolphin, Gwenview, Okular, etc.)

![KDE Plasma](screenshot.png)

### Budgie

Gnome based, really enjoyed the simple look and feel. It is quite light and fast.

Unfortunately, is also lagging behind the pack, not very polished and riddled with issues (like the annoying bug in the lockscreen that is also a security risk).

Trying a comeback with Cosmic.

### Gnome

I used Gnome for some time, but it felt sluggish, laggy and most gnome apps are oversimplified so I ended up replacing them.

Customization is limited, can be achieved with some extensions that are stable most of the time, but it feels like an afterthought. Finally, software updates are not that often, and when they happen, stuff breaks (like it happened after upgrade from Gnome 46 to 47).

Discouraged by some crashes and freezes.

### Tiling Window Managers

Gave Hyprland a go, but having a HiDPI display and wanting scaling, proved to be an ugly experience (pixelated fonts or very tiny output). Liked the simplicity and speed though, but it not yet for me. Still, from time to time I revisit and play around with it. I will include a module to install and configure a ready-to-use Hyprland desktop.

[HyDE project](https://github.com/HyDE-Project/HyDE) looks promising, though it is kind of heavy on the customizations. Took enough configs and scripts from this project to make it work, but I am not sure if I will keep using it.

## Why YAML and mise?

YAML is easier to parse with tools like [yq](https://mikefarah.gitbook.io/yq) and human-readable. Package definitions support host-specific filtering, allowing the same config to work across multiple machines.

[mise](https://mise.jdx.dev/) provides a simple task runner with environment management. It's faster and more flexible than make or taskfile.

### Why not nix?

I don't yet like it and do not have the time to learn it.

## Design

- `mise-tasks/` contains bash scripts organized by functionality (packages, system, apps, network, etc.)
- `packages/*.yaml` defines packages to install, with optional host-specific filtering
  - Format:

    ```yaml
    - name: package-name # or "aur/package-name" for AUR packages
      desc: Description of the package
      hosts: # optional, if not present installs everywhere
        - hostname1
        - hostname2
      state: present # or absent
    ```

  - Package scripts automatically filter by hostname - packages without `hosts` field install everywhere, those with `hosts` array only install on matching machines
- `copy/` and `symlink/` directories hold system and user configuration files to be copied or symlinked

## License

[MIT](LICENSE)
