#!/usr/bin/env python3
import os
import gi

gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib  # noqa: E402
import argparse  # noqa: E402
import logging  # noqa: E402
import sys  # noqa: E402
import signal  # noqa: E402
import json  # noqa: E402
import pyutils.logger as logger  # noqa: E402
from pyutils.xdg_base_dirs import (  # noqa: E402
    xdg_state_home,
    xdg_cache_home,
)


logger = logger.get_logger()


#
# Global dictionary to store the track, artist, and total duration
# for each player.  Key = player_name
#
players_data = {}
current_player = None


def load_env_file(filepath: str) -> None:
    """
    Load environment variables from filepath.
    Each line should be in the format KEY=VALUE.
    Lines starting with '#' are ignored.
    """
    try:
        with open(filepath, encoding="utf-8") as f:
            for line in f:
                if line.strip() and not line.startswith("#"):
                    if line.startswith("export "):
                        line = line[len("export ") :]
                    key, value = line.strip().split("=", 1)
                    os.environ[key] = value.strip('"')
    except (FileNotFoundError, OSError) as e:
        logger.error(f"Error loading environment file {filepath}: {e}")


def format_time(seconds) -> str:
    """
    Convert seconds into mm:ss format.
    """
    m = int(seconds // 60)
    s = int(seconds % 60)
    return f"{m:02d}:{s:02d}"


def create_tooltip_text(
    artist, track, current_position_seconds, duration_seconds, p_name, loop_status=None, shuffle_status=None
) -> str:
    """
    Build the tooltip text showing artist, track, current position vs duration, loop status, and shuffle status.
    Use Pango markup to style the artist as italic and the track as bold.
    """
    tooltip = ""

    if artist or track:
        tooltip += f'<span foreground="{track_color}"><b>{track}</b></span>'
        tooltip += f'\n<span foreground="{artist_color}"><i>{artist}</i></span>\n'
        if duration_seconds > 0:
            progress = int((current_position_seconds / duration_seconds) * 20)
            bar = f'<span foreground="{progress_color}">{"━" * progress}</span><span foreground="{empty_color}">{"─" * (20 - progress)}</span>'
            tooltip += f'<span foreground="{time_color}">{format_time(current_position_seconds)}</span> {bar} <span foreground="{time_color}">{format_time(duration_seconds)}</span>'
            # Add loop status directly below the bar if available
            if loop_status is not None:
                loop_glyphs = {
                    "None": "󰑓 No Loop",
                    "Track": "󰑖 Loop Once",
                    "Playlist": "󰑘 Loop Playlist"
                }
                loop_display = loop_glyphs.get(loop_status, str(loop_status))
                tooltip += f"\n<span foreground='{track_color}'>{loop_display}</span>"
            # Add shuffle status below loop status if available
            if shuffle_status is not None:
                shuffle_glyph = "󰒟 Shuffle On" if shuffle_status else "󰒞 Shuffle Off"
                tooltip += f"\n<span foreground='{track_color}'>{shuffle_glyph}</span>"
        tooltip += f'\n<span>{p_name}</span>'
    # Always add usage tips at the bottom
    tooltip += (
        f"\n<span size='x-small' foreground='{track_color}'>"
        f"\n󰐎 click to play/pause"  # play/pause glyph
        f"\n scroll to seek"         # seek glyph
        f"\n󱥣 rightclick for options" # right-click/options glyph
        f"</span>"
    )
    return tooltip


def format_artist_track(artist, track, playing, max_length):
    # Use the appropriate prefix based on playback status
    prefix = prefix_playing if playing else prefix_paused
    prefix_separator = "  "
    full_length = len(artist + track)

    if track and not artist:
        if len(track) != len(track[:max_length]):
            track = track[:max_length].rstrip() + "…"
        output_text = f"{prefix}{prefix_separator}<b>{track}</b>"
    elif track and artist:
        artist = artist.split(",")[0].split("&")[0].strip()
        if full_length > max_length:
            # proportion how to share max length between track and artist
            artist_weight = 0.65
            artist_limit = min(int(max_length * artist_weight), len(artist))
            a_gain = max(0, artist_weight - (artist_limit / max_length))
            track_weight = 1 - artist_weight + a_gain
            track_limit = min(int(max_length * track_weight), len(track))
            t_gain = max(0, track_weight - (track_limit / max_length))

            if a_gain == 0 and t_gain > 0:
                gain = int(max_length * t_gain)
                artist_limit = artist_limit + gain
            elif a_gain > 0 and t_gain == 0:
                gain = int(max_length * t_gain)
                artist_limit = artist_limit + gain

            if len(artist) != len(artist[:artist_limit]):
                artist = artist[:artist_limit].rstrip() + "…"
            if len(track) != len(track[:track_limit]):
                track = track[:track_limit].rstrip() + "…"

        output_text = f"{prefix}{prefix_separator}<i>{artist}</i>{artist_track_separator}<b>{track}</b>"
    else:
        # If there is a player but no track/artist, show player name instead of 'Nothing playing'
        if current_player and hasattr(current_player, 'props') and hasattr(current_player.props, 'player_name'):
            output_text = f"<b>{standby_text} {current_player.props.player_name}</b>"
        else:
            output_text = "<b>{standby_text}</b>"
    return output_text


def write_output(track, artist, playing, player, tooltip_text):
    logger.info("Writing output")

    output_data = {
        "text": escape(format_artist_track(artist, track, playing, max_length_module)),
        "class": "custom-" + player.props.player_name,
        "alt": player.props.player_name,
        "tooltip": escape(tooltip_text),
    }

    sys.stdout.write(json.dumps(output_data) + "\n")
    sys.stdout.flush()


def on_play(player, status, manager):
    set_player(manager, player)


def on_playback_changed(player, status, manager):
    logger.info("Received new playback status")
    if status == "Playing":
        set_player(manager, player)
        update_positions(manager)
    on_metadata(player, player.props.metadata, manager)


def on_metadata(player, metadata, manager):
    """
    Called whenever the metadata changes (new track, etc.).
    We extract track, artist, total duration, store them in players_data,
    and immediately write the output once so it refreshes promptly.
    """
    logger.info("Received new metadata")

    # Grab track and artist
    full_track = player.get_title() or ""
    full_artist = player.get_artist() or ""
    track, artist = full_track, full_artist

    # Duration and position
    try:
        length_microseconds = metadata["mpris:length"]
        duration_seconds = length_microseconds / 1e6
    except (KeyError, TypeError):
        duration_seconds = 0
    # current_position_seconds = player.get_position() / 1e6

    # Store relevant info so our timer callback can update the position every second
    players_data[player.props.player_name] = {
        "track": track,
        "artist": artist,
        "duration": duration_seconds,
    }


def on_player_appeared(manager, player, selected_players=None):
    if player is not None and (
        selected_players is None or player.name in selected_players
    ):
        p = init_player(manager, player)
        set_player(manager, p)
        # Start polling if it is not already running
        if not hasattr(manager, '_polling') or not manager._polling:
            manager._polling = True
            GLib.timeout_add_seconds(1, poll_if_players, manager)
        update_positions(manager)  # Force immediate update when a new player appears
    else:
        logger.debug("New player appeared, but it's not the selected player, skipping")


def on_player_vanished(manager, player, loop):
    logger.info("Player has vanished")
    if current_player.props.player_name == player.props.player_name:
        if manager.props.players:
            set_player(manager, manager.props.players[0])
            on_metadata(player, player.props.metadata, manager)
            update_positions(manager)

        # Remove from our stored dictionary
        p_name = player.props.player_name
        if p_name in players_data:
            del players_data[p_name]
        # Output "standby" text
        output = {
            "text": standby_text,
            "class": "custom-nothing-playing",
            "alt": "player-closed",
            "tooltip": "",
        }
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()


def init_player(manager, name):
    logger.debug("Initialize player: {player}".format(player=name.name))
    player = Playerctl.Player.new_from_name(name)
    player.connect("playback-status", on_playback_changed, manager)
    player.connect("playback-status::playing", on_play, manager)
    player.connect("metadata", on_metadata, manager)
    manager.manage_player(player)
    on_metadata(player, player.props.metadata, manager)
    return player


def update_positions(manager):
    """
    This is the callback run once every second.
    It loops over each known player, reads its current position,
    updates the tooltip, and rewrites the output to stdout.
    Returns True to keep polling, or False to stop polling if no players.
    """
    # Refresh the player list in case new players appeared after startup
    try:
        manager.props.player_names  # This triggers a refresh in Playerctl
    except Exception as e:
        logger.warning(f"Could not refresh player names: {e}")
    if manager.props.players:
        tooltip_text = ""
        for player in manager.props.players:
            p_name = player.props.player_name
            if p_name not in players_data:
                try:
                    on_metadata(player, player.props.metadata, manager)
                except Exception as e:
                    logger.error(f"Failed to update metadata for {p_name}: {e}")
                if p_name not in players_data:
                    continue
            track = players_data[p_name]["track"]
            artist = players_data[p_name]["artist"]
            duration_seconds = players_data[p_name]["duration"]
            try:
                loop_status = player.get_loop_status()
            except Exception:
                loop_status = None
            try:
                shuffle_status = player.get_shuffle()
            except Exception:
                shuffle_status = None
            try:
                position = player.get_position() / 1e6
            except Exception as e:
                logger.warning(f"Could not get position for {p_name}: {e}")
                continue
            tooltip_text += (
                create_tooltip_text(
                    artist, track, position, duration_seconds, p_name, loop_status, shuffle_status
                )
            )
        player = manager.props.players[0]
        p_name = player.props.player_name
        track = players_data[p_name]["track"]
        artist = players_data[p_name]["artist"]
        duration_seconds = players_data[p_name]["duration"]
        try:
            loop_status = player.get_loop_status()
        except Exception:
            loop_status = None
        try:
            shuffle_status = player.get_shuffle()
        except Exception:
            shuffle_status = None
        write_output(track, artist, player.props.status == "Playing", player, tooltip_text)
        return True  # Keep polling if there are players
    else:
        # No players: output standby text and stop polling
        output = {
            "text": standby_text,
            "class": "custom-nothing-playing",
            "alt": "player-closed",
            "tooltip": "",
        }
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()
        return False  # Stop polling if no players


def poll_if_players(manager):
    # Helper to only poll when there are players
    keep_polling = update_positions(manager)
    if keep_polling:
        return True  # Continue polling
    else:
        manager._polling = False
        return False  # Stop polling until a player appears


def signal_handler(sig, frame):
    logger.debug("Received signal to stop, exiting")
    sys.stdout.write("\n")
    sys.stdout.flush()
    sys.exit(0)


def parse_arguments():
    """
    The options for prefix/paused/max_length/standby_text are loaded from env variables.
    """
    parser = argparse.ArgumentParser(
        description="A media player status tool with customizable display options."
    )

    # Define for which player we're listening
    parser.add_argument("--players", nargs="*", type=str)
    parser.add_argument("--player", type=str)

    return parser.parse_args()


def main():
    global \
        prefix_playing, \
        prefix_paused, \
        max_length_module, \
        standby_text, \
        artist_track_separator
    global \
        artist_color, \
        artist_weight, \
        track_color, \
        progress_color, \
        empty_color, \
        time_color

    # Load environment variables from your config file:
    config_file = os.path.join(xdg_state_home(), "hyde", "config")
    colors_file = os.path.join(xdg_cache_home(), "hyde/wall.dcol")
    if os.path.exists(config_file):
        load_env_file(config_file)
    if os.path.exists(colors_file):
        load_env_file(colors_file)

    # Pull values from environment variables
    # You can configure these in ~/.config/hyde/config.toml
    prefix_playing = os.getenv("MEDIAPLAYER_PREFIX_PLAYING", "")
    prefix_paused = os.getenv("MEDIAPLAYER_PREFIX_PAUSED", "  ")
    max_length_module = int(os.getenv("MEDIAPLAYER_MAX_LENGTH", "70"))
    standby_text = os.getenv("MEDIAPLAYER_STANDBY_TEXT", "  Music")
    artist_track_separator = os.getenv("MEDIAPLAYER_ARTIST_TRACK_SEPARATOR", "  ")

    # Initialize tooltip colors
    artist_color = os.getenv(
        "MEDIAPLAYER_TOOLTIP_ARTIST_COLOR", "#" + os.getenv("dcol_3xa8", "FFFFFF")
    )
    track_color = os.getenv(
        "MEDIAPLAYER_TOOLTIP_TRACK_COLOR", "#" + os.getenv("dcol_txt1", "FFFFFF")
    )
    progress_color = os.getenv(
        "MEDIAPLAYER_TOOLTIP_PROGRESS_COLOR", "#" + os.getenv("dcol_pry4", "FFFFFF")
    )
    empty_color = os.getenv(
        "MEDIAPLAYER_TOOLTIP_EMPTY_COLOR", "#" + os.getenv("dcol_1xa3", "FFFFFF")
    )
    time_color = os.getenv(
        "MEDIAPLAYER_TOOLTIP_TIME_COLOR", "#" + os.getenv("dcol_txt1", "FFFFFF")
    )
    artist_weight = os.getenv("MEDIAPLAYER_ARTIST_WEIGHT", 0.65)
    players = os.getenv("MEDIAPLAYER_PLAYERS", None)
    if players:
        players = players.split(",")

    arguments = parse_arguments()
    player_found = False

    # Initialize logging
    logging.basicConfig(
        stream=sys.stdout,
        level=logging.DEBUG,
        format="%(name)s %(levelname)s %(message)s",
    )

    logger.debug("Arguments received {}".format(vars(arguments)))

    manager = Playerctl.PlayerManager()
    choose = False
    if not (arguments.players or arguments.player) and not players:
        players = [name.name for name in manager.props.player_names]
    else:
        choose = True
        if arguments.players:
            players = arguments.players
        elif arguments.player:
            players = [arguments.player]
    loop = GLib.MainLoop()

    manager.connect(
        "name-appeared",
        # if player didn't select a player(s)
        # then allow all mediaplayer.py to watch
        # all players that appear
        lambda *args: on_player_appeared(*args, players if choose else None),
    )
    manager.connect("player-vanished", lambda *args: on_player_vanished(*args, loop))

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGPIPE, signal_handler)

    found = [None] * len(players)
    for player in manager.props.player_names:
        if (
            players is not None and player.name not in players
        ) or player.name == "plasma-browser-integration":
            logger.debug(
                "{player} is not the filtered player, skipping it".format(
                    player=player.name
                )
            )
            continue
        p = init_player(manager, player)
        found[players.index(player.name)] = p
    if found:
        found = list(filter(lambda x: x is not None, found))
        if found:
            try:
                p = next(player for player in found if player.props.status == "Playing")
            except StopIteration:
                p = None
            if not p:
                p = found[0]
            set_player(manager, p)
            player_found = True
    # If no player is found, generate the standby output and continue running the loop
    if not player_found:
        output = {
            "text": standby_text,
            "class": "custom-nothing-playing",
            "alt": "player-closed",
            "tooltip": "",
        }
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()
    # Set up a single 1-second timer to update song position only if there are players
    if manager.props.players:
        manager._polling = True
        GLib.timeout_add_seconds(1, poll_if_players, manager)
    else:
        manager._polling = False
    loop.run()


def set_player(manager, player):
    global current_player
    if current_player:
        try:
            if current_player.props.player_name != player.props.player_name:
                current_player.pause()
        except Exception as e:
            logger.warning(f"Could not pause previous player: {e}")
    current_player = player
    manager.move_player_to_top(player)


def escape(string):
    return string.replace("&", "&amp;")


if __name__ == "__main__":
    main()
