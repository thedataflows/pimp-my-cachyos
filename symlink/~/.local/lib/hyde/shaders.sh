#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

# Set variables
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
shaders_dir="$confDir/hypr/shaders"

# Ensure the shaders directory exists
if [ ! -d "$shaders_dir" ]; then
    send_notifs -i "preferences-desktop-display" "Error" "Shaders directory does not exist at $shaders_dir"
    exit 1
fi

# Show help function
show_help() {
    cat <<HELP
Usage: $0 [OPTIONS]

Options:
    --select | -S       Select a shader from the available options
    --reload | -r       Reload the current shader
    --help   | -h       Show this help message
HELP
}

if [ -z "${*}" ]; then
    echo "No arguments provided"
    show_help
fi

# Define long options
LONG_OPTS="select,help,reload"
SHORT_OPTS="Shr"
# Parse options
PARSED=$(getopt --options ${SHORT_OPTS} --longoptions "${LONG_OPTS}" --name "$0" -- "$@")
if [ $? -ne 0 ]; then
    exit 2
fi
eval set -- "${PARSED}"

# Default action if no arguments are provided
if [ -z "$1" ]; then
    echo "No arguments provided"
    show_help
    exit 1
fi

# Functions
fn_select() {
    # List all .frag shaders except user-defines, disable, and .cache
    shader_items=$(find -L "$shaders_dir" -maxdepth 1 -name "*.frag" ! -name "disable.frag" ! -name ".compiled.cache.glsl" -print0 2>/dev/null | xargs -0 -n1 basename | sed 's/\.frag$//')
    # Add 'disable' on top if it exists
    if [ -f "$shaders_dir/disable.frag" ]; then
        shader_items="disable\n$shader_items"
    fi

    if [ -z "$shader_items" ]; then
        send_notifs -i "preferences-desktop-display" "Error" "No .frag files found in $shaders_dir"
        exit 1
    fi

    # Set rofi scaling
    font_scale="${ROFI_SHADER_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # Set font name
    font_name=${ROFI_SHADER_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # Set rofi font override
    font_override="* {font: \"${font_name:-\"JetBrainsMono Nerd Font\"} ${font_scale}\";}"

    # Window and element styling
    hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    wind_border=$((hypr_border * 3 / 2))
    elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

    # Display options using Rofi
    selected_shader=$(echo -e "$shader_items" |
        rofi -dmenu -i -select "$HYPR_SHADER" \
            -p "Select shader" \
            -theme-str "entry { placeholder: \"🎨 Select shader...\"; }" \
            -theme-str "${font_override}" \
            -theme-str "${r_override}" \
            -theme-str "$(get_rofi_pos)" \
            -theme "clipboard")

    # Exit if no selection was made
    if [ -z "$selected_shader" ]; then
        exit 0
    fi

    set_conf "HYPR_SHADER" "$selected_shader"
    fn_update "$selected_shader"
    send_notifs -i "preferences-desktop-display" "Shader:" "$selected_shader"
}

fn_reload() {
    if [ -z "$HYPR_SHADER" ]; then
        HYPR_SHADER="disable"
    fi
    set_conf "HYPR_SHADER" "$HYPR_SHADER"
    fn_update "$HYPR_SHADER"
    send_notifs -i "preferences-desktop-display" "Shader reloaded:" "$HYPR_SHADER"
}

concat_shader_files() {
    local files=("$@")
    local version_directive=""
    local compiled_file="$shaders_dir/.compiled.cache.glsl"

    # Extract version directive from the main .frag file (last file in array)
    local main_frag_file="${files[-1]}"
    if [ -f "$main_frag_file" ]; then
        version_directive=$(grep -E '^\s*#version\s+' "$main_frag_file" | head -n1)
        if [ -n "$version_directive" ]; then
            print_log -g "Found version directive" " $version_directive"
        else
            print_log -y "Warning" " No #version directive found in $main_frag_file"
            version_directive="#version 300 es" # Default fallback
        fi
    fi

    # Start with version directive
    echo "$version_directive" >"$compiled_file"
    echo "" >>"$compiled_file"

    # Process each file and remove #version directives
    for f in "${files[@]}"; do
        if [ -f "$f" ]; then
            print_log -g "Processing shader" " file: $f"
            # Remove #version lines and append to compiled file
            sed '/^\s*#version\s/d' "$f" >>"$compiled_file"
            echo "" >>"$compiled_file" # Add blank line between files
        fi
    done
}

parse_includes_and_update() {
    local selected_shader="$1"
    local files=()

    # Look for a comment line with !source = ... (whitespace-insensitive)
    local source_var
    source_var=$(grep -iE '^\s*//\s*!source\s*=\s*.*' "$shaders_dir/${selected_shader}.frag" 2>/dev/null | head -n1 | sed -E 's/^\s*\/\/\s*!source\s*=\s*//I' | xargs)
    if [ -n "$source_var" ]; then
        # Expand variables in the source path
        source_var=$(eval echo "$source_var")
        if [ -f "$source_var" ]; then
            files+=("$source_var")
            print_log -g "Found source include" " $source_var"
        else
            print_log -y "Warning" " Source file not found: $source_var"
        fi
    fi

    # Automatically include .inc file if it exists
    local inc_file="$shaders_dir/${selected_shader}.inc"
    if [ -f "$inc_file" ]; then
        files+=("$inc_file")
        print_log -g "Found inc file" " $inc_file"
    fi

    # Add main .frag file last (to extract version from it)
    files+=("$shaders_dir/${selected_shader}.frag")

    # Compile the shader files
    if concat_shader_files "${files[@]}"; then
        print_log -g "Shader" " $selected_shader compiled successfully."
    else
        print_log -r "Error" " Failed to compile shader $selected_shader"
        return 1
    fi
    # Write the shaders.conf file with the requested banner and path
    cat <<EOF >"$confDir/hypr/shaders.conf"

#! █▀ █░█ ▄▀█ █▀▄ █▀▀ █▀█ █▀
#! ▄█ █▀█ █▀█ █▄▀ ██▄ █▀▄ ▄█

# *┌────────────────────────────────────────────────────────────────────────────┐
# *│                                                                            |
# *│ HyDE Controlled content DO NOT EDIT!                                      |
# *│ Edit or add shaders in the ./shaders/ directory                           |
# *│ and run the 'shaders.sh --select' command to update this file             |
# *│ Modify ./shaders/shader-name.inc to add your own custom defines         |
# *│ The 'shader.sh' script will automatically copy this file to the cache     |
# *│ and the cache will be used in the shader                                  |
# *│                                                                            |
# *└────────────────────────────────────────────────────────────────────────────┘

# name of the shader
\$SCREEN_SHADER = "${selected_shader}"
# path to the shader
\$SCREEN_SHADER_PATH = "$shaders_dir/${selected_shader}.frag"
# path to the compiled shader // override this in '../hyde/config.toml'
\$SCREEN_SHADER_COMPILED = ${XDG_CONFIG_HOME}/hypr/shaders/.compiled.cache.glsl


EOF
}

fn_update() {
    parse_includes_and_update "$1"
}

# Process options
while true; do
    case "$1" in
    -S | --select)
        fn_select
        exit 0
        ;;
    -r | --reload)
        fn_reload
        exit 0
        ;;
    --help | -h)
        show_help
        exit 0
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: $1"
        show_help
        exit 1
        ;;
    esac
done
