#!/usr/bin/env python3
"""Migrate from packages/ + symlink/ + copy/ to apps/<appname>/ self-contained modules."""

import shutil
import os
import re
from pathlib import Path
from collections import defaultdict

# -----------------------------------------------------------------------------
# Mapping of config-bearing apps to their packages and config paths.
# Packages may be prefixed with "aur/" or repo names.
# -----------------------------------------------------------------------------
CONFIG_APPS = {
    "dolphin": {"packages": ["dolphin"], "config_dirs": [".config/dolphinrc", ".local/share/kxmlgui5/dolphin"]},
    "okular": {"packages": ["okular"], "config_dirs": [".config/okularpartrc", ".local/share/kxmlgui5/okular"]},
    "spectacle": {"packages": ["spectacle"], "config_dirs": [".config/spectaclerc"]},
    "viddy": {"packages": [], "config_dirs": [".config/viddy.toml"]},
    "thorium": {"packages": ["aur/thorium-browser-updated-bin"], "config_dirs": []},

    "atuin": {"packages": ["atuin"], "config_dirs": [".config/atuin"]},
    "bat": {"packages": ["bat"], "config_dirs": [".config/bat"]},
    "btop": {"packages": ["btop"], "config_dirs": [".config/btop"]},
    "easyeffects": {"packages": ["easyeffects"], "config_dirs": [".config/easyeffects"]},
    "fastfetch": {"packages": ["fastfetch"], "config_dirs": [".config/fastfetch"]},
    "ghostty": {"packages": ["ghostty"], "config_dirs": [".config/ghostty"]},
    "glow": {"packages": ["glow"], "config_dirs": [".config/glow"]},
    "grsync": {"packages": ["grsync"], "config_dirs": [".config/grsync"]},
    "htop": {"packages": ["htop"], "config_dirs": [".config/htop"]},
    "keepassxc": {"packages": ["keepassxc"], "config_dirs": [".config/keepassxc"]},
    "kew": {"packages": ["kew"], "config_dirs": [".config/kew"]},
    "kitty": {"packages": ["kitty"], "config_dirs": [".config/kitty"]},
    "lazygit": {"packages": ["lazygit"], "config_dirs": [".config/lazygit"]},
    "mc": {"packages": ["mc"], "config_dirs": [".config/mc"]},
    "mise": {"packages": ["mise"], "config_dirs": [".config/mise"]},
    "niri": {"packages": ["niri"], "config_dirs": [".config/niri"]},
    "nvtop": {"packages": ["nvtop"], "config_dirs": [".config/nvtop"]},
    "opencode": {"packages": ["opencode"], "config_dirs": [".config/opencode"]},
    "strawberry": {"packages": ["strawberry"], "config_dirs": [".config/strawberry"]},
    "television": {"packages": ["television"], "config_dirs": [".config/television"]},
    "tmux": {"packages": ["tmux"], "config_dirs": [".config/tmux"]},
    "vlc": {"packages": ["vlc"], "config_dirs": [".config/vlc"]},
    "yazi": {"packages": ["yazi"], "config_dirs": [".config/yazi"]},
    "zed": {"packages": ["zed"], "config_dirs": [".config/zed"]},
    "zellij": {"packages": ["zellij"], "config_dirs": [".config/zellij"]},

    # Config dirs with non-matching / AUR / grouped packages
    "bookokrat": {"packages": ["aur/bookokrat-bin"], "config_dirs": [".config/bookokrat"]},
    "betterbird": {"packages": ["betterbird-bin"], "config_dirs": [".local/share/applications/eu.betterbird.Betterbird.desktop"]},
    "looking-glass": {"packages": ["looking-glass", "looking-glass-module-dkms"], "config_dirs": [".local/share/applications/looking-glass-custom.desktop"]},
    "dank-material-shell": {
        "packages": ["dms-shell-niri", "quickshell", "dgop", "aur/dsearch-bin", "accountsservice", "i2c-tools", "kdeconnect"],
        "config_dirs": [".config/DankMaterialShell"],
    },
    "kopia": {"packages": ["aur/kopia-bin", "aur/kopia-ui-bin"], "config_dirs": [".config/kopia"]},
    "mangohud": {"packages": ["mangohud"], "config_dirs": [".config/MangoHud"]},
    "nwg-look": {"packages": ["aur/nwg-look"], "config_dirs": [".config/nwg-look"]},
    "oh-my-posh": {"packages": ["aur/oh-my-posh-bin"], "config_dirs": [".config/oh-my-posh"]},
    "openrgb": {"packages": ["openrgb"], "config_dirs": [".config/OpenRGB"]},
    "pacseek": {"packages": ["pacseek"], "config_dirs": [".config/pacseek"]},
    "panel-colorizer": {"packages": ["aur/panel-colorizer"], "config_dirs": [".config/panel-colorizer"]},
    "rustdesk": {"packages": ["rustdesk"], "config_dirs": [".config/rustdesk"]},
    "baloo": {"packages": ["baloo"], "config_dirs": [".config/baloofilerc"]},
    "plasma-systemmonitor": {"packages": ["plasma-systemmonitor"], "config_dirs": [".local/share/plasma-systemmonitor"]},
    "rsync": {"packages": ["rsync"], "config_dirs": [".config/rsyncd.conf", ".config/rsyncd.sh"]},
    "sesh": {"packages": ["aur/sesh-bin"], "config_dirs": [".config/sesh"]},
    "signal": {"packages": ["signal-desktop"], "config_dirs": [".config/signal-desktop-flags.conf"]},
    "swaylock": {"packages": ["swaylock"], "config_dirs": [".config/swaylock"]},
    "syncthingtray": {"packages": ["aur/syncthingtray-qt6"], "config_dirs": [".config/autostart/syncthingtray-qt6.desktop"]},
    "xsettingsd": {"packages": ["xsettingsd"], "config_dirs": [".config/xsettingsd"]},
    "xdg-desktop-portal": {
        "packages": ["xdg-desktop-portal-wlr", "xdg-desktop-portal-gtk", "xdg-desktop-portal-kde", "xdg-desktop-portal-gnome"],
        "config_dirs": [".config/xdg-desktop-portal"],
    },
    "code": {"packages": ["aur/visual-studio-code-bin"], "config_dirs": [".config/Code"]},
    "micro": {"packages": ["micro"], "config_dirs": [".config/micro"]},
    "mpv": {"packages": ["mpv"], "config_dirs": [".config/mpv"]},
    "menus": {"packages": [], "config_dirs": [".config/menus"]},
    "systemd": {"packages": [], "config_dirs": [".config/systemd"]},

    # Top-level files
    "zsh": {"packages": ["zsh", "aur/zsh-antidote"], "config_dirs": [".zshrc", ".zsh_plugins.txt", ".profile"]},
    "git": {"packages": ["git", "git-delta"], "config_dirs": [".gitconfig"]},
    "fzf": {"packages": ["fzf", "aur/fzf-tab-completion-git"], "config_dirs": [".fzf"]},
    "gtk": {"packages": [], "config_dirs": [".gtkrc-2.0"]},
    "aliases": {"packages": [], "config_dirs": [".aliases"]},
    "iommu-viewer": {"packages": [], "config_dirs": ["iommu-viewer.sh"]},

    # Special dirs
    "gnupg": {"packages": ["gnupg"], "config_dirs": [".gnupg"]},
    "icons": {"packages": [], "config_dirs": [".local/share/icons"]},
    "wallpaper": {"packages": [], "config_dirs": ["Pictures"]},

    # System-level configs from copy/
    "system-tmux": {"packages": ["tmux"], "system_config_files": ["etc/tmux.conf"]},
    "system-keyd": {"packages": ["keyd"], "system_config_files": ["etc/keyd/default.conf"]},
    "system-modprobe": {"packages": [], "system_config_files": ["etc/modprobe.d/*"]},
    "system-modules": {"packages": [], "system_config_files": ["etc/modules-load.d/*"]},
    "system-pipewire": {"packages": [], "system_config_files": ["etc/pipewire/pipewire.conf.d/*"]},
    "system-samba": {"packages": ["samba"], "system_config_files": ["etc/samba/smb.conf"]},
    "system-snapper": {"packages": ["snapper"], "system_config_files": ["etc/snapper/configs/*"]},
    "system-sysctl": {"packages": [], "system_config_files": ["etc/sysctl.d/*"]},
    "system-udev": {"packages": [], "system_config_files": ["etc/udev/rules.d/*"]},
    "system-dbus": {"packages": [], "system_config_files": ["usr/local/share/dbus-1/services/*"]},
    "system-nvidia": {"packages": [], "system_config_files": ["etc/nvidia/nvidia-application-profiles-rc.d/*"]},
    "system-nsswitch": {"packages": [], "system_config_files": ["etc/nsswitch.conf"]},
    "system-plasma": {"packages": [], "system_config_files": ["etc/plasmalogin.conf"]},
    "system-htop": {"packages": ["htop"], "system_config_files": ["etc/htoprc"]},
    "system-libvirt": {"packages": ["libvirt"], "system_config_files": ["etc/libvirt/hooks/*"]},
}

# -----------------------------------------------------------------------------
# Categories that become apps for packages without dedicated configs.
# Niri is also listed so its remaining packages are merged into the niri app.
# -----------------------------------------------------------------------------
CATEGORY_APPS = [
    "ai", "android", "backup", "boot", "cloud", "containers", "crypto",
    "desktop", "development", "files", "fonts", "gaming", "graphics",
    "internet", "kde-desktop", "multimedia", "network", "niri", "productivity",
    "remote", "security", "system", "text",
]

# Packages that should be marked as absent (removed, not installed).
ABSENT_PACKAGES = {
    "grub",
    "grub-btrfs",
    "grub-customizer",
    "grub-hook",
    "catppuccin-mocha-grub-theme-git",
}


def load_yaml(path: Path):
    import yaml

    with open(path) as f:
        return yaml.safe_load(f) or []


def main():
    repo = Path(__file__).resolve().parent
    apps_dir = repo / "apps"
    old_packages = repo / "packages"
    old_symlink = repo / "symlink"
    old_copy = repo / "copy"
    old_apps_tasks = repo / "mise-tasks" / "apps"

    if shutil.which("yq") is None:
        pass  # yq is used by the packages tasks, not this script

    # Read all existing category packages (or a backup from a previous run)
    backup_file = apps_dir / ".migration-pkgs.json"
    pkgs_by_category = {}
    if old_packages.exists():
        for pf in sorted(old_packages.glob("*.yaml")):
            pkgs_by_category[pf.stem] = load_yaml(pf)
        # Save backup so the script can be re-run after packages/ is removed
        apps_dir.mkdir(parents=True, exist_ok=True)
        import json

        with open(backup_file, "w") as f:
            json.dump(pkgs_by_category, f, indent=2, sort_keys=True)
    elif backup_file.exists():
        import json

        with open(backup_file) as f:
            pkgs_by_category = json.load(f)
    else:
        raise SystemExit(
            "ERROR: packages/ directory and backup file are both missing. "
            "Cannot determine category packages."
        )

    # Determine which packages are claimed by config apps
    claimed = set()
    for spec in CONFIG_APPS.values():
        for p in spec.get("packages", []):
            claimed.add(p)

    # Prepare all app definitions
    apps = {}

    # 1. Config apps
    for app, spec in CONFIG_APPS.items():
        apps[app] = {
            "packages": list(spec.get("packages", [])),
            "config_dirs": list(spec.get("config_dirs", [])),
            "system_config_files": list(spec.get("system_config_files", [])),
        }

    # 2. Category apps (remaining packages from each category file)
    for cat in CATEGORY_APPS:
        entries = pkgs_by_category.get(cat, [])
        remaining = [e for e in entries if isinstance(e, dict) and e.get("name") not in claimed]
        if not remaining:
            continue
        if cat == "niri":
            # Merge remaining niri packages into the existing niri app
            apps["niri"]["packages"] = sorted(set(apps["niri"]["packages"]) | set(e["name"] for e in remaining))
            continue
        apps[cat] = {
            "packages": [e["name"] for e in remaining],
            "config_dirs": [],
            "system_config_files": [],
        }

    # 3. Dynamically assign any remaining config files/dirs from symlink/~
    #    that are not already covered by CONFIG_APPS, so no files are lost.
    already_assigned = set()
    for spec in apps.values():
        for cfg in spec["config_dirs"]:
            already_assigned.add(cfg)

    home_dir = old_symlink / "~"
    dir_to_app = {
        "DankMaterialShell": "dank-material-shell",
        "MangoHud": "mangohud",
        "OpenRGB": "openrgb",
        "Code": "code",
    }
    config_file_to_app = {
        "dolphinrc": "dolphin",
        "okularpartrc": "okular",
        "spectaclerc": "spectacle",
        "viddy.toml": "viddy",
        "baloofilerc": "baloo",
        "rsyncd.conf": "rsync",
        "rsyncd.sh": "rsync",
        "code-flags.conf": "code",
        "electron-flags.conf": "desktop",
        "signal-desktop-flags.conf": "signal",
        "spotify-flags.conf": "desktop",
    }
    config_dir_to_app = {
        "dolphin": "dolphin",
    }
    local_dir_to_app = {
        ("share", "kxmlgui5", "dolphin"): "dolphin",
        ("share", "kxmlgui5", "okular"): "okular",
        ("share", "plasma-systemmonitor"): "plasma-systemmonitor",
    }

    def ensure_app(name):
        if name not in apps:
            apps[name] = {"packages": [], "config_dirs": [], "system_config_files": []}

    if home_dir.exists():
        for item in sorted(home_dir.iterdir()):
            rel = item.relative_to(home_dir)
            if str(rel) in already_assigned:
                continue
            if str(rel) == ".config":
                for cfg in sorted(item.iterdir()):
                    cfg_rel = cfg.relative_to(home_dir)
                    if str(cfg_rel) in already_assigned:
                        continue
                    if cfg.is_dir():
                        app_name = config_dir_to_app.get(cfg.name, dir_to_app.get(cfg.name, cfg.name.lower()))
                        existing = {a.lower().replace("-", ""): a for a in apps}
                        lookup = app_name.lower().replace("-", "")
                        app_name = existing.get(lookup, app_name)
                        ensure_app(app_name)
                        apps[app_name]["config_dirs"].append(str(cfg_rel))
                    else:
                        app_name = config_file_to_app.get(cfg.name, "kde-desktop")
                        ensure_app(app_name)
                        apps[app_name]["config_dirs"].append(str(cfg_rel))
            elif str(rel) == ".local":
                for sub1 in sorted(item.iterdir()):
                    for sub2 in sorted(sub1.iterdir()):
                        sub2_rel = sub2.relative_to(home_dir)
                        if str(sub2_rel) in already_assigned:
                            continue
                        if sub1.name != "share":
                            ensure_app("kde-desktop")
                            apps["kde-desktop"]["config_dirs"].append(str(sub2_rel))
                            continue
                        if sub2.name == "applications":
                            app_name = "desktop-entries"
                        elif sub2.name == "icons":
                            app_name = "icons"
                        elif sub2.name == "kxmlgui5":
                            # kxmlgui5 has per-app subdirectories
                            for sub3 in sorted(sub2.iterdir()):
                                sub3_rel = sub3.relative_to(home_dir)
                                if str(sub3_rel) in already_assigned:
                                    continue
                                if sub3.name == "dolphin":
                                    app_name = "dolphin"
                                elif sub3.name == "okular":
                                    app_name = "okular"
                                else:
                                    app_name = "kde-desktop"
                                ensure_app(app_name)
                                apps[app_name]["config_dirs"].append(str(sub3_rel))
                            continue
                        else:
                            app_name = local_dir_to_app.get(("share", sub2.name), "kde-desktop")
                        ensure_app(app_name)
                        apps[app_name]["config_dirs"].append(str(sub2_rel))
            elif str(rel) == "Pictures":
                ensure_app("wallpaper")
                apps["wallpaper"]["config_dirs"].append(str(rel))
            else:
                top_level_mapping = {
                    ".aliases": "aliases",
                    ".fzf": "fzf",
                    ".gitconfig": "git",
                    ".gtkrc-2.0": "gtk",
                    ".profile": "zsh",
                    ".zsh_plugins.txt": "zsh",
                    ".zshrc": "zsh",
                    "iommu-viewer.sh": "iommu-viewer",
                    ".gnupg": "gnupg",
                }
                app_name = top_level_mapping.get(str(rel))
                if app_name:
                    ensure_app(app_name)
                    apps[app_name]["config_dirs"].append(str(rel))

    # Remove empty apps
    apps = {k: v for k, v in apps.items() if v["packages"] or v["config_dirs"] or v["system_config_files"]}

    # Autostart files belong to their owning apps, not a shared autostart app.
    AUTOSTART_FILES = {
        "OpenRGB.desktop": "openrgb",
        "easyeffects-service.desktop": "easyeffects",
        "org.keepassxc.KeePassXC.desktop": "keepassxc",
        "syncthingtray-qt6.desktop": "syncthingtray",
        "kopia-ui.desktop": "kopia",
        "thorium-browser.desktop": "thorium",
        "thorium-hnpfjngllnobngcgfapefoaidbinmjnm-Default.desktop": "thorium",
    }
    if "autostart" in apps:
        apps.pop("autostart")
    for filename, app_name in AUTOSTART_FILES.items():
        if app_name in apps:
            apps[app_name]["config_dirs"].append(f".config/autostart/{filename}")

    # Desktop entry files belong to their owning apps, not a shared desktop-entries app.
    DESKTOP_ENTRY_FILES = {
        "eu.betterbird.Betterbird.desktop": "betterbird",
        "looking-glass-custom.desktop": "looking-glass",
    }
    if "desktop-entries" in apps:
        apps.pop("desktop-entries")
    for filename, app_name in DESKTOP_ENTRY_FILES.items():
        if app_name in apps:
            apps[app_name]["config_dirs"].append(f".local/share/applications/{filename}")

    # Create app directories and move files
    for app, spec in apps.items():
        app_dir = apps_dir / app
        config_dir = app_dir / "config"
        system_config_dir = app_dir / "system-config"
        task_dir = app_dir / "mise-tasks"
        app_dir.mkdir(parents=True, exist_ok=True)
        task_dir.mkdir(parents=True, exist_ok=True)

        # Move user config dirs/files
        for cfg in spec["config_dirs"]:
            src = old_symlink / "~" / cfg
            if not src.exists():
                continue
            dst = config_dir / cfg
            dst.parent.mkdir(parents=True, exist_ok=True)
            if dst.exists() or dst.is_symlink():
                shutil.rmtree(dst, ignore_errors=True)
            shutil.move(str(src), str(dst))

        # Move system config files (with glob support)
        for scfg in spec["system_config_files"]:
            if "*" in scfg:
                src_dir = old_copy / scfg.split("/*")[0]
                if src_dir.exists():
                    for src in src_dir.iterdir():
                        if src.is_file():
                            rel = src.relative_to(old_copy)
                            dst = system_config_dir / rel
                            dst.parent.mkdir(parents=True, exist_ok=True)
                            if dst.exists() or dst.is_symlink():
                                dst.unlink()
                            shutil.move(str(src), str(dst))
            else:
                src = old_copy / scfg
                if src.exists():
                    dst = system_config_dir / scfg
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    if dst.exists() or dst.is_symlink():
                        dst.unlink()
                    shutil.move(str(src), str(dst))

        # Write packages.yaml
        pkg_entries = []
        for p in spec["packages"]:
            desc = ""
            for entries in pkgs_by_category.values():
                for e in entries:
                    if isinstance(e, dict) and e.get("name") == p and e.get("desc"):
                        desc = e["desc"]
                        break
                if desc:
                    break
            entry = {"name": p, "desc": desc}
            if p in ABSENT_PACKAGES:
                entry["state"] = "absent"
            pkg_entries.append(entry)
        if pkg_entries:
            import yaml

            with open(app_dir / "packages.yaml", "w") as f:
                yaml.dump(pkg_entries, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

        # Write task file
        task_file = task_dir / f"{app}.sh"
        task_content = f"""#!/bin/env bash
#MISE description="Install and configure {app}"
#MISE interactive=true

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${{BASH_COMMAND}}\" exited with status $?"' ERR

_APP_DIR="${{MISE_TASK_DIR}}/.."

if [[ -s "$_APP_DIR/packages.yaml" ]]; then
  mise run packages "$_APP_DIR/packages.yaml"
fi

if [[ -d "$_APP_DIR/config" ]]; then
  mise -E user dotfiles apply
fi

if [[ -d "$_APP_DIR/system-config" ]]; then
  sudo mise -E system dotfiles apply
fi
"""

        # Preserve custom task files that were moved from mise-tasks/ (e.g. baloo.sh).
        if not task_file.exists():
            task_file.write_text(task_content)
        task_file.chmod(0o755)

    # Remove deprecated Brave autostart entries that may still be in the source tree.
    for app_dir in sorted(apps_dir.iterdir()):
        if not app_dir.is_dir():
            continue
        autostart_dir = app_dir / "config" / ".config" / "autostart"
        if autostart_dir.exists():
            for entry in list(autostart_dir.iterdir()):
                if "brave" in entry.name.lower():
                    if entry.is_dir():
                        shutil.rmtree(entry)
                    else:
                        entry.unlink()

    # Move autostart files to their owning apps and remove the now-empty autostart app.
    autostart_app = apps_dir / "autostart"
    autostart_config = autostart_app / "config" / ".config" / "autostart"
    if autostart_config.exists():
        for filename, app_name in AUTOSTART_FILES.items():
            src = autostart_config / filename
            if not src.exists():
                continue
            dst_dir = apps_dir / app_name / "config" / ".config" / "autostart"
            dst_dir.mkdir(parents=True, exist_ok=True)
            dst = dst_dir / filename
            if dst.exists() or dst.is_symlink():
                if dst.is_dir():
                    shutil.rmtree(dst)
                else:
                    dst.unlink()
            shutil.move(str(src), str(dst))
    if autostart_app.exists():
        shutil.rmtree(autostart_app)

    # Move desktop entry files to their owning apps and remove the desktop-entries app.
    desktop_entries_app = apps_dir / "desktop-entries"
    if desktop_entries_app.exists():
        shutil.rmtree(desktop_entries_app)

    for filename, app_name in DESKTOP_ENTRY_FILES.items():
        target_dir = apps_dir / app_name / "config" / ".local" / "share" / "applications"
        target_dir.mkdir(parents=True, exist_ok=True)
        dst = target_dir / filename
        if dst.exists() or dst.is_symlink():
            if dst.is_dir():
                shutil.rmtree(dst)
            else:
                dst.unlink()
        # Find the file anywhere in the apps tree and move it to the target app.
        for src in sorted(apps_dir.rglob(filename)):
            if src == dst:
                continue
            shutil.move(str(src), str(dst))
            break

    # Move top-level config files to their owning apps based on config_file_to_app.
    for cfg_file, app_name in config_file_to_app.items():
        target_dir = apps_dir / app_name / "config" / ".config"
        target_dir.mkdir(parents=True, exist_ok=True)
        dst = target_dir / cfg_file
        for src in sorted(apps_dir.rglob(f".config/{cfg_file}")):
            if src == dst:
                continue
            if dst.exists() or dst.is_symlink():
                if dst.is_dir():
                    shutil.rmtree(dst)
                else:
                    dst.unlink()
            shutil.move(str(src), str(dst))
            break

    # Move autostart files to their owning apps based on AUTOSTART_FILES.
    for filename, app_name in AUTOSTART_FILES.items():
        target_dir = apps_dir / app_name / "config" / ".config" / "autostart"
        target_dir.mkdir(parents=True, exist_ok=True)
        dst = target_dir / filename
        for src in sorted(apps_dir.rglob(f".config/autostart/{filename}")):
            if src == dst:
                continue
            if dst.exists() or dst.is_symlink():
                if dst.is_dir():
                    shutil.rmtree(dst)
                else:
                    dst.unlink()
            shutil.move(str(src), str(dst))
            break

    # Move .local/share directories to their owning apps based on local_dir_to_app.
    for components, app_name in local_dir_to_app.items():
        rel_path = Path(".local").joinpath(*components)
        target_dir = apps_dir / app_name / "config" / rel_path
        target_dir.parent.mkdir(parents=True, exist_ok=True)
        for src in sorted(apps_dir.rglob(str(rel_path))):
            if src == target_dir:
                continue
            if target_dir.exists() or target_dir.is_symlink():
                if target_dir.is_dir():
                    shutil.rmtree(target_dir)
                else:
                    target_dir.unlink()
            shutil.move(str(src), str(target_dir))
            break

    # Move the custom baloo task from kde-desktop to the dedicated baloo app.
    baloo_src = apps_dir / "kde-desktop" / "mise-tasks" / "baloo.sh"
    if baloo_src.exists():
        baloo_dst = apps_dir / "baloo" / "mise-tasks" / "baloo.sh"
        baloo_dst.parent.mkdir(parents=True, exist_ok=True)
        if baloo_dst.exists() or baloo_dst.is_symlink():
            baloo_dst.unlink()
        shutil.move(str(baloo_src), str(baloo_dst))

    # Remove empty config directories left behind in category apps.
    for app_dir in sorted(apps_dir.iterdir()):
        if not app_dir.is_dir():
            continue
        config_dir = app_dir / "config"
        if config_dir.exists() and not any(config_dir.rglob("*")):
            config_dir.rmdir()

    # Special case: Thorium chrome-flags.conf -> thorium-flags.conf
    thorium_app = apps_dir / "thorium"
    thorium_config = thorium_app / "config"
    thorium_app.mkdir(parents=True, exist_ok=True)
    thorium_config.mkdir(parents=True, exist_ok=True)
    envd_dir = apps_dir / "environment.d" / "config" / ".config" / "environment.d"
    thorium_envd = thorium_config / ".config" / "environment.d"
    chrome_flags = envd_dir / "chrome-flags.conf"
    thorium_envd.mkdir(parents=True, exist_ok=True)
    if chrome_flags.exists():
        dst = thorium_envd / "thorium-flags.conf"
        if dst.exists() or dst.is_symlink():
            dst.unlink()
        shutil.move(str(chrome_flags), str(dst))

    # Rebuild dotfiles entries from the apps/ tree (idempotent, works even if
    # symlink/ and copy/ were already removed in a previous run).
    user_dotfiles = {}
    system_dotfiles = {}

    for app_dir in sorted(apps_dir.iterdir()):
        if not app_dir.is_dir():
            continue
        app = app_dir.name
        config_dir = app_dir / "config"
        system_config_dir = app_dir / "system-config"

        if config_dir.exists():
            for cfg in sorted(config_dir.iterdir()):
                rel = cfg.relative_to(config_dir)
                if cfg.is_dir():
                    # Directories are symlinked with symlink-each
                    if str(rel) == ".config":
                        for sub in sorted(cfg.iterdir()):
                            if sub.is_dir():
                                if sub.name in ("autostart", "environment.d"):
                                    # These directories are split across apps;
                                    # symlink each file individually so multiple apps
                                    # can own files in the same target directory.
                                    for f in sorted(sub.rglob("*")):
                                        if f.is_file():
                                            f_rel = f.relative_to(cfg)
                                            target = f"~/.config/{f_rel}"
                                            user_dotfiles[target] = f"apps/{app}/config/.config/{f_rel}"
                                else:
                                    target = f"~/.config/{sub.name}"
                                    user_dotfiles[target] = {
                                        "source": f"apps/{app}/config/.config/{sub.name}",
                                        "mode": "symlink-each",
                                    }
                            else:
                                # Top-level files in ~/.config are symlinked directly
                                target = f"~/.config/{sub.name}"
                                user_dotfiles[target] = f"apps/{app}/config/.config/{sub.name}"
                    elif str(rel) == ".local":
                        for sub1 in sorted(cfg.iterdir()):
                            for sub2 in sorted(sub1.iterdir()):
                                if sub1.name == "share" and sub2.name == "kxmlgui5":
                                    for sub3 in sorted(sub2.iterdir()):
                                        target = f"~/.local/{sub1.name}/{sub2.name}/{sub3.name}"
                                        user_dotfiles[target] = {
                                            "source": f"apps/{app}/config/.local/{sub1.name}/{sub2.name}/{sub3.name}",
                                            "mode": "symlink-each",
                                        }
                                elif sub1.name == "share" and sub2.name == "applications":
                                    # Desktop entry files are split across apps.
                                    for f in sorted(sub2.rglob("*")):
                                        if f.is_file():
                                            f_rel = f.relative_to(cfg)
                                            target = f"~/.local/{f_rel}"
                                            user_dotfiles[target] = f"apps/{app}/config/.local/{f_rel}"
                                else:
                                    target = f"~/.local/{sub1.name}/{sub2.name}"
                                    user_dotfiles[target] = {
                                        "source": f"apps/{app}/config/.local/{sub1.name}/{sub2.name}",
                                        "mode": "symlink-each",
                                    }
                    elif str(rel) == "Pictures":
                        target = "~/Pictures"
                        user_dotfiles[target] = {
                            "source": f"apps/{app}/config/Pictures",
                            "mode": "symlink-each",
                        }
                    else:
                        target = f"~/{rel}"
                        user_dotfiles[target] = {
                            "source": f"apps/{app}/config/{rel}",
                            "mode": "symlink-each",
                        }
                else:
                    # Files are symlinked directly
                    target = f"~/{rel}"
                    user_dotfiles[target] = f"apps/{app}/config/{rel}"

        if system_config_dir.exists():
            for scfg in sorted(system_config_dir.rglob("*")):
                if scfg.is_dir():
                    continue
                rel = scfg.relative_to(system_config_dir)
                target = "/" + str(rel)
                system_dotfiles[target] = f"apps/{app}/system-config/{rel}"

    # /root/.gtkrc-2.0 mirrors the user gtkrc.
    gtkrc_user = apps_dir / "gtk" / "config" / ".gtkrc-2.0"
    if gtkrc_user.exists():
        system_dotfiles["/root/.gtkrc-2.0"] = "apps/gtk/config/.gtkrc-2.0"

    # Generate mise.user.toml
    user_toml = repo / "mise.user.toml"
    user_lines = [
        "[settings]",
        'dotfiles.default_mode = "symlink"',
        "",
        "[dotfiles]",
    ]
    for target in sorted(user_dotfiles):
        entry = user_dotfiles[target]
        if isinstance(entry, dict):
            user_lines.append(f'"{target}" = {{ source = "{entry["source"]}", mode = "{entry["mode"]}" }}')
        else:
            user_lines.append(f'"{target}" = "{entry}"')
    user_toml.write_text("\n".join(user_lines) + "\n")

    # Generate mise.system.toml
    system_toml = repo / "mise.system.toml"
    system_lines = [
        "[settings]",
        'dotfiles.default_mode = "copy"',
        "",
        "[dotfiles]",
    ]
    for target in sorted(system_dotfiles):
        system_lines.append(f'"{target}" = {{ source = "{system_dotfiles[target]}", mode = "copy" }}')
    system_toml.write_text("\n".join(system_lines) + "\n")

    # Update mise.toml with task_config.includes
    mise_toml = repo / "mise.toml"
    # Preserve existing [env] and other sections; remove any previous [task_config] block
    task_config = """[task_config]
includes = [
    "mise-tasks",
    "apps/*/mise-tasks",
]
"""
    existing = mise_toml.read_text() if mise_toml.exists() else ""
    # Strip any existing [task_config] block (from the start of [task_config] to the next top-level section or EOF)
    existing = re.sub(r"\n?\[task_config\].*?(?=\n\[|\Z)", "", existing, flags=re.DOTALL)
    existing = existing.rstrip() + "\n\n" + task_config
    mise_toml.write_text(existing)

    # Generate the combined packages task
    packages_sh = repo / "mise-tasks" / "packages.sh"
    packages_sh.write_text("""#!/bin/env bash
#MISE description="Manage packages defined in yaml lists"
#MISE interactive=true

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \\"${BASH_COMMAND}\\" exited with status $?"' ERR

type paru &> /dev/null || sudo pacman -Sy --noconfirm paru
type yq &> /dev/null || $PARU go-yq
type fd &> /dev/null || $PARU fd

_HOSTNAME=$(hostname)

if [[ $# -eq 0 ]]; then
  mapfile -t _PACKAGE_FILES < <(fd --type file '\\.ya?ml' "${MISE_PROJECT_ROOT:-.}/apps")
else
  _PACKAGE_FILES=("$@")
fi

## Add packages
for F in "${_PACKAGE_FILES[@]}"; do
  [[ -r "$F" ]] || continue
  _PACKAGES=$(yq --no-colors --no-doc ".[] | select(.state!=\\"absent\\" and .state!=\\"removed\\") | select(.hosts == null or (.hosts | contains([\\"$_HOSTNAME\\"]))) | .name" "$F" 2>/dev/null || true)
  [[ -n "$_PACKAGES" ]] || continue
  echo ""
  echo ">> add: $F"
  set -x
  #shellcheck disable=SC2086
  $PARU $_PACKAGES
  { set +x; } 2>/dev/null
done

## Remove packages marked absent/removed
for F in "${_PACKAGE_FILES[@]}"; do
  [[ -r "$F" ]] || continue
  _PACKAGES=$(yq --no-colors --no-doc ".[] | select(.state==\\"absent\\" or .state==\\"removed\\") | select(.hosts == null or (.hosts | contains([\\"$_HOSTNAME\\"]))) | .name" "$F" 2>/dev/null || true)
  [[ -n "$_PACKAGES" ]] || continue
  #shellcheck disable=SC2086
  _PACKAGES=$(paru -Q $_PACKAGES 2>/dev/null | cut -f1 -d' ' || true)
  [[ -n "$_PACKAGES" ]] || continue
  echo ""
  echo ">> remove: $F"
  set -x
  #shellcheck disable=SC2086
  paru --remove --recursive --noconfirm $_PACKAGES
  { set +x; } 2>/dev/null
done
""")
    packages_sh.chmod(0o755)

    # Remove old split packages tasks if they still exist.
    old_packages_dir = repo / "mise-tasks" / "packages"
    if old_packages_dir.exists():
        shutil.rmtree(old_packages_dir)

    # Move mise-tasks/desktop/* tasks into their respective apps.
    desktop_tasks = repo / "mise-tasks" / "desktop"
    desktop_task_moves = {
        "baloo.sh": "baloo",
        "dms-niri.sh": "dank-material-shell",
        "kde-icon-theme.sh": "kde-desktop",
        "root-gtk.sh": "gtk",
    }
    if desktop_tasks.exists():
        for task_name, app in desktop_task_moves.items():
            src = desktop_tasks / task_name
            if not src.exists():
                continue
            dst_dir = apps_dir / app / "mise-tasks"
            dst_dir.mkdir(parents=True, exist_ok=True)
            dst = dst_dir / task_name
            if dst.exists():
                dst.unlink()
            shutil.move(str(src), str(dst))
            if task_name == "dms-niri.sh":
                # Update the moved task to reference the new app tasks.
                text = dst.read_text()
                text = re.sub(r"mise run packages packages/niri\.yaml", "mise run niri", text)
                text = re.sub(r"mise run packages packages/dank-material-shell\.yaml", "mise run dank-material-shell", text)
                text = re.sub(r"mise -E user dotfiles apply", "", text)
                dst.write_text(text)
        # Remove the empty desktop tasks directory.
        if desktop_tasks.exists() and not any(desktop_tasks.iterdir()):
            desktop_tasks.rmdir()

    # Remove old app task files (they are now in apps/<app>/mise-tasks/)
    if old_apps_tasks.exists():
        shutil.rmtree(old_apps_tasks)

    # Generate mise-tasks/all.sh
    all_sh = repo / "mise-tasks" / "all.sh"
    all_lines = [
        "#!/bin/env bash",
        "#MISE description=\"Run all tasks in the proper order\"",
        "#MISE interactive=true",
        "",
        "set -Eeuo pipefail",
        'trap \'echo "[ERROR] on line $LINENO: \\"${BASH_COMMAND}\\" exited with status $?"\' ERR',
        "",
        "## Software installation",
        "mise run packages",
        "",
        "## Configure: apps",
    ]
    for app in sorted(apps):
        all_lines.append(f"mise run {app}")
    all_lines.extend([
        "",
        "## Configure: network",
        "mise run network:firewall",
        "mise run network:sshd",
        "",
        "## Configure: system",
        "mise run system:limine",
        "mise run system:snapper",
        "mise run system:services",
        "mise run system:video-drivers",
        "mise run system:faillock",
        "mise run system:locale",
        "mise run system:mountpoints",
        "mise run system:smb",
        "mise run system:edk2-ovmf-downgrade",
        "mise run system:virtualization",
        "",
        "## Configure: user",
        "mise run user:shell",
        "# mise run user:containerd",
        "",
        "## Configure: desktop",
        "mise run kde-icon-theme",
        "mise run root-gtk",
        "",
        "## Configure: Alternative Desktop Environments (optional)",
        "mise run dms-niri",
        "",
        "## Cleanup",
        "mise run user:cleanup",
        "",
    ])
    all_sh.write_text("\n".join(all_lines) + "\n")
    all_sh.chmod(0o755)

    # Ensure all mise task files are marked interactive so sudo prompts work.
    def ensure_interactive(path):
        text = path.read_text()
        if "#MISE interactive=true" in text:
            return
        lines = text.splitlines()
        new_lines = []
        inserted = False
        for line in lines:
            new_lines.append(line)
            if line.startswith("#MISE description=") and not inserted:
                new_lines.append("#MISE interactive=true")
                inserted = True
        if not inserted:
            # No description line; insert after shebang
            new_lines = []
            for line in lines:
                new_lines.append(line)
                if line.startswith("#!/") and not inserted:
                    new_lines.append("#MISE interactive=true")
                    inserted = True
        path.write_text("\n".join(new_lines) + "\n")

    for task_file in sorted(repo.rglob("mise-tasks/**/*.sh")):
        ensure_interactive(task_file)

    # Update README.md usage section to reference the new apps/ layout
    readme = repo / "README.md"
    if readme.exists():
        text = readme.read_text()
        text = text.replace(
            "   - Apply dotfiles: `mise run all` (runs `mise -E user dotfiles apply` + system apply) or `mise -E user dotfiles apply` for user files only\n   - Validate dotfiles state: `mise -E user dotfiles status --missing`\n   - Add files to this repo: `mise -E user dotfiles add ~/.config/foo` (user) or `sudo mise -E system dotfiles add /etc/foo.conf` (system/root)",
            "   - Apps are self-contained in `apps/<appname>/` with `packages.yaml`, `config/`, and `mise-tasks/<appname>`.\n   - Install/configure one app: `mise run <appname>` (e.g., `mise run atuin`)\n   - Install/configure all: `mise run all`\n   - Validate dotfiles state: `mise -E user dotfiles status --missing`\n   - Add files to this repo: `mise -E user dotfiles add ~/.config/foo` (user) or `sudo mise -E system dotfiles add /etc/foo.conf` (system/root)",
        )
        text = text.replace(
            "   - Individual tasks can be run as well: `mr packages`, etc.",
            "   - Individual apps: `mr <appname>` (e.g., `mr atuin`) or `mr system-htop` for system tasks",
        )

        # Add or update migration howto for users moving to v4.0.0
        migration_howto = """## Migration to v4.0.0\n\nVersion 4.0.0 introduced self-contained `apps/<appname>/` modules.\nTo migrate from an earlier version:\n\n1. Pull the v4.0.0 changes.\n2. Run the migration script from the repository root:\n   ```sh\n   ./migrate-to-apps.py\n   ```\n3. The script will:\n   - Move configs from `symlink/`, `copy/`, and packages from `packages/` into `apps/<appname>/`.\n   - Regenerate `mise.user.toml`, `mise.system.toml`, `mise.toml`, and `mise-tasks/all.sh`.\n   - Discover app tasks via `apps/*/mise-tasks/`.\n   - Re-apply user dotfiles so your home symlinks point to the new locations.\n4. For system dotfiles, run manually with sudo:\n   ```sh\n   sudo -E MISE_EXPERIMENTAL=1 mise -E system dotfiles apply\n   ```\n5. Use `mise run <appname>` to install/configure individual apps, or `mise run all` for everything.\n\nThe old `packages/`, `symlink/`, and `copy/` directories are removed by the migration script.\nThe script is idempotent; re-running it rebuilds the dotfiles configs and reapplies user dotfiles.\n"""
        if "## Migration to v4.0.0" in text:
            # Replace existing section
            text = re.sub(r"## Migration to v4\.0\.0.*?(?=\n## |\Z)", migration_howto, text, flags=re.DOTALL)
        elif "## Migration from v4.0.0" in text:
            # Replace old mis-named section
            text = re.sub(r"## Migration from v4\.0\.0.*?(?=\n## |\Z)", migration_howto, text, flags=re.DOTALL)
        else:
            text = text.rstrip() + "\n\n" + migration_howto + "\n"
        readme.write_text(text)
        readme.write_text(text)

    # Remove old directories
    if old_packages.exists():
        shutil.rmtree(old_packages)
    if old_symlink.exists():
        shutil.rmtree(old_symlink)
    if old_copy.exists():
        shutil.rmtree(old_copy)

    # Re-apply user dotfiles so existing symlinks are updated to the new layout
    print("Re-applying dotfiles to update existing symlinks...")

    # Remove stale symlinks that still point to the old symlink/ tree so mise
    # recreates them pointing to the new apps/<app>/config/ locations.
    repo_name = repo.name
    for home_item in Path.home().rglob("*"):
        if home_item.is_symlink():
            try:
                link_target = os.readlink(home_item)
            except OSError:
                continue
            if f"{repo_name}/symlink/~" in link_target:
                try:
                    home_item.unlink()
                except OSError:
                    pass

    os.system("MISE_EXPERIMENTAL=1 mise -E user dotfiles apply")
    os.system("sudo -E MISE_EXPERIMENTAL=1 mise -E system dotfiles apply || true")

    print(f"Migration complete. Created {len(apps)} apps under {apps_dir}.")
    print("Apps:", sorted(apps))


if __name__ == "__main__":
    main()
