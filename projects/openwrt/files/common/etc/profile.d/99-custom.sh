#!/bin/sh

case "$-" in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

confirm_action() {
  prompt="$1"
  printf "%s [y/N]: " "$prompt"
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      echo "Cancelled."
      return 1
      ;;
  esac
}

reboot() {
  confirm_action "Confirm reboot" || return 1
  command reboot "$@"
}

poweroff() {
  confirm_action "Confirm poweroff" || return 1
  command poweroff "$@"
}

halt() {
  confirm_action "Confirm halt" || return 1
  command halt "$@"
}

sysupgrade() {
  confirm_action "Confirm sysupgrade" || return 1
  command sysupgrade "$@"
}

rm() {
  case " $* " in
    *" -rf "*|*" -fr "*|*" --no-preserve-root "*)
      confirm_action "Confirm rm $*" || return 1
      ;;
  esac
  command rm "$@"
}

export PS1='[\u@\h \W]\$ '
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
