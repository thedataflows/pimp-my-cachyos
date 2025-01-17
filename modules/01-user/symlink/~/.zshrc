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
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/tokyo.toml)" &>/dev/null

## Fzf
source ~/.fzf

## Atuin
eval "$(atuin init zsh)"

## Zoxide
eval "$(zoxide init --cmd cd zsh)"

## Mise-en-place
eval "$(mise activate zsh)"
eval "$(mise env)"

## Yazi
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

[[ ! -t 0 || $SHLVL -gt 1 ]] || fastfetch

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
# Alt+Right
bindkey "^[[1;3C" forward-word
# Alt+Left
bindkey "^[[1;3D" backward-word
# Del
bindkey "\e[3~" delete-char
# Alt+Del
bindkey "\e[3;3~" kill-word

setopt no_flowcontrol
bindkey -s '^S' 'ggh^M'
