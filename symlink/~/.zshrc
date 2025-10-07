_SITE_FUNCTIONS=~/.local/share/zsh/site-functions
[[ -d "$_SITE_FUNCTIONS" ]] || mkdir -p "$_SITE_FUNCTIONS"
fpath=("$_SITE_FUNCTIONS" $fpath)

## Profile
[[ -r ~/.profile ]] && . ~/.profile

## Aliases
# shellcheck disable=SC1090
[[ -r ~/.aliases ]] && . ~/.aliases

## Allow root to connect to X
xhost +si:localuser:root &>/dev/null

## zsh-autocomplete
source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

## zsh-syntax-highlighting
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

## fzf-zsh-completion
source /usr/share/fzf-tab-completion/zsh/fzf-zsh-completion.sh
bindkey '^I' fzf_completion

## Oh-my-posh
PARENT_PROCESS=$(ps -p $PPID -o comm=)
## Space separated list of program names that should not load oh-my-posh
PROCLIST=""
[[ ! " $PROCLIST " =~ " $PARENT_PROCESS " ]] && \
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/catppuccin_mocha.omp.json)" &>/dev/null

## Fzf
source ~/.fzf

## Atuin
eval "$(atuin init zsh)"

## Zoxide
eval "$(zoxide init --cmd cd zsh)"

## Mise-en-place
eval "$(mise activate zsh)"
eval "$(mise env)"
[[ -f "$_SITE_FUNCTIONS/_mise" ]] || mise completion zsh  > "$_SITE_FUNCTIONS/_mise"

## Yazi
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
bindkey -s '^Y' 'y^M'

# [[ ! -t 0 || $SHLVL -gt 1 ]] || fastfetch

## Key bindings
## Home/End keys not working in tmux: https://stackoverflow.com/a/27467524/3735961
# Home
bindkey "^[[H" beginning-of-line
bindkey "\E[1~" beginning-of-line
bindkey "\E[H" beginning-of-line
# End
bindkey "^[[F" end-of-line
bindkey "\E[4~" end-of-line
bindkey "\E[F" end-of-line
# Ctrl+Right
bindkey "^[[1;5C" forward-word
# Ctrl+Left
bindkey "^[[1;5D" backward-word
# Del
bindkey "\e[3~" delete-char
# Ctrl+Del
bindkey "\e[3;5~" kill-word
# Ctrl+Backspace
bindkey "^H" backward-kill-word

setopt no_flowcontrol
bindkey -s '^S' 'ggh^M'
bindkey -s '^B' 'btop^M'
