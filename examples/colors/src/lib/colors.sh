## Color functions [@bashly-upgrade colors]
## This file is a part of Bashly standard library
##
## Usage:
## Use any of the functions below to color or format a portion of a string.
##
##   echo "before $(red this is red) after"
##   echo "before $(green_bold this is green_bold) after"
##
## Color output will be disabled if `NO_COLOR` environment variable is set
## in compliance with https://no-color.org/
##
## In case you wish to enable auto detection for color output based on the
## terminal being interactive (TTY), call `enable_auto_colors` in your 
## `src/initialize.sh` (Run `bashly add hooks` to add this file).
##
enable_auto_colors() {
  ## If NO_COLOR has not been set and stdout is not a TTY, disable colors
  if [[ -z ${NO_COLOR+x} && ! -t 1 ]]; then
    NO_COLOR=1
  fi
}

print_in_color() {
  local color="$1"
  shift
  if [[ "${NO_COLOR:-}" == "" ]]; then
    printf "$color%b\e[0m\n" "$*"
  else
    printf "%b\n" "$*"
  fi
}

red() { print_in_color "\e[31m" "$*"; }
green() { print_in_color "\e[32m" "$*"; }
yellow() { print_in_color "\e[33m" "$*"; }
blue() { print_in_color "\e[34m" "$*"; }
magenta() { print_in_color "\e[35m" "$*"; }
cyan() { print_in_color "\e[36m" "$*"; }
black() { print_in_color "\e[30m" "$*"; }
white() { print_in_color "\e[37m" "$*"; }

bold() { print_in_color "\e[1m" "$*"; }
underlined() { print_in_color "\e[4m" "$*"; }
bold_underlined() { print_in_color "\e[1;4m" "$*"; }

red_bold() { print_in_color "\e[1;31m" "$*"; }
green_bold() { print_in_color "\e[1;32m" "$*"; }
yellow_bold() { print_in_color "\e[1;33m" "$*"; }
blue_bold() { print_in_color "\e[1;34m" "$*"; }
magenta_bold() { print_in_color "\e[1;35m" "$*"; }
cyan_bold() { print_in_color "\e[1;36m" "$*"; }
black_bold() { print_in_color "\e[1;30m" "$*"; }
white_bold() { print_in_color "\e[1;37m" "$*"; }

red_underlined() { print_in_color "\e[4;31m" "$*"; }
green_underlined() { print_in_color "\e[4;32m" "$*"; }
yellow_underlined() { print_in_color "\e[4;33m" "$*"; }
blue_underlined() { print_in_color "\e[4;34m" "$*"; }
magenta_underlined() { print_in_color "\e[4;35m" "$*"; }
cyan_underlined() { print_in_color "\e[4;36m" "$*"; }
black_underlined() { print_in_color "\e[4;30m" "$*"; }
white_underlined() { print_in_color "\e[4;37m" "$*"; }
