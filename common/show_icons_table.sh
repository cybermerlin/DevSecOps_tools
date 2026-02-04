#!/usr/bin/env bash

# to show all symbols (ANSI icons) which you can use in your system
# 
# example to use> showU8Variation 16 26
# Show UTF8 table using: VARIATION SELECTOR-16 (U+FE0F)
# U026yx    0 1 2 3 4 5 6 7 8 9 A B C D E F  0️1️2️3️4️5️6️7️8️9️A️B️C️D️E️F️
# ------    -------------------------------  -------------------------------
# U0260x    ☀ ☁ ☂ ☃ ☄ ★ ☆ ☇ ☈ ☉ ☊ ☋ ☌ ☍ ☎ ☏  ☀️☁️☂️☃️☄️★️☆️☇️☈️☉️☊️☋️☌️☍️☎️☏️
# U0261x    ☐ ☑ ☒ ☓ ☔☕☖ ☗ ☘ ☙ ☚ ☛ ☜ ☝ ☞ ☟  ☐️☑️☒️☓️☔️☕️☖️☗️☘️☙️☚️☛️☜️☝️☞️☟️
# U0262x    ☠ ☡ ☢ ☣ ☤ ☥ ☦ ☧ ☨ ☩ ☪ ☫ ☬ ☭ ☮ ☯  ☠️☡️☢️☣️☤️☥️☦️☧️☨️☩️☪️☫️☬️☭️☮️☯️
# U0263x    ☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷ ☸ ☹ ☺ ☻ ☼ ☽ ☾ ☿  ☰️☱️☲️☳️☴️☵️☶️☷️☸️☹️☺️☻️☼️☽️☾️☿️
# U0264x    ♀ ♁ ♂ ♃ ♄ ♅ ♆ ♇ ♈♉♊♋♌♍♎♏ ♀️♁️♂️♃️♄️♅️♆️♇️♈️♉️♊️♋️♌️♍️♎️♏️
# U0265x    ♐♑♒♓♔ ♕ ♖ ♗ ♘ ♙ ♚ ♛ ♜ ♝ ♞ ♟  ♐️♑️♒️♓️♔️♕️♖️♗️♘️♙️♚️♛️♜️♝️♞️♟️
# U0266x    ♠ ♡ ♢ ♣ ♤ ♥ ♦ ♧ ♨ ♩ ♪ ♫ ♬ ♭ ♮ ♯  ♠️♡️♢️♣️♤️♥️♦️♧️♨️♩️♪️♫️♬️♭️♮️♯️
# U0267x    ♰ ♱ ♲ ♳ ♴ ♵ ♶ ♷ ♸ ♹ ♺ ♻ ♼ ♽ ♾ ♿ ♰️♱️♲️♳️♴️♵️♶️♷️♸️♹️♺️♻️♼️♽️♾️♿️
# U0268x    ⚀ ⚁ ⚂ ⚃ ⚄ ⚅ ⚆ ⚇ ⚈ ⚉ ⚊ ⚋ ⚌ ⚍ ⚎ ⚏  ⚀️⚁️⚂️⚃️⚄️⚅️⚆️⚇️⚈️⚉️⚊️⚋️⚌️⚍️⚎️⚏️
# U0269x    ⚐ ⚑ ⚒ ⚓⚔ ⚕ ⚖ ⚗ ⚘ ⚙ ⚚ ⚛ ⚜ ⚝ ⚞ ⚟  ⚐️⚑️⚒️⚓️⚔️⚕️⚖️⚗️⚘️⚙️⚚️⚛️⚜️⚝️⚞️⚟️
# U026Ax    ⚠ ⚡⚢ ⚣ ⚤ ⚥ ⚦ ⚧ ⚨ ⚩ ⚪⚫⚬ ⚭ ⚮ ⚯  ⚠️⚡️⚢️⚣️⚤️⚥️⚦️⚧️⚨️⚩️⚪️⚫️⚬️⚭️⚮️⚯️
# U026Bx    ⚰ ⚱ ⚲ ⚳ ⚴ ⚵ ⚶ ⚷ ⚸ ⚹ ⚺ ⚻ ⚼ ⚽⚾⚿  ⚰️⚱️⚲️⚳️⚴️⚵️⚶️⚷️⚸️⚹️⚺️⚻️⚼️⚽️⚾️⚿️
# U026Cx    ⛀ ⛁ ⛂ ⛃ ⛄⛅⛆ ⛇ ⛈ ⛉ ⛊ ⛋ ⛌ ⛍ ⛎⛏  ⛀️⛁️⛂️⛃️⛄️⛅️⛆️⛇️⛈️⛉️⛊️⛋️⛌️⛍️⛎️⛏️
# U026Dx    ⛐ ⛑ ⛒ ⛓ ⛔⛕ ⛖ ⛗ ⛘ ⛙ ⛚ ⛛ ⛜ ⛝ ⛞ ⛟  ⛐️⛑️⛒️⛓️⛔️⛕️⛖️⛗️⛘️⛙️⛚️⛛️⛜️⛝️⛞️⛟️
# U026Ex    ⛠ ⛡ ⛢ ⛣ ⛤ ⛥ ⛦ ⛧ ⛨ ⛩ ⛪⛫ ⛬ ⛭ ⛮ ⛯  ⛠️⛡️⛢️⛣️⛤️⛥️⛦️⛧️⛨️⛩️⛪️⛫️⛬️⛭️⛮️⛯️
# U026Fx    ⛰ ⛱ ⛲⛳⛴ ⛵⛶ ⛷ ⛸ ⛹ ⛺⛻ ⛼ ⛽⛾ ⛿  ⛰️⛱️⛲️⛳️⛴️⛵️⛶️⛷️⛸️⛹️⛺️⛻️⛼️⛽️⛾️⛿️

showU8Variation () {
  local _i _a _f _e _t
  printf -v _t '%31s' ''
  _t=${_t// /-}
  printf -v _t '%s    %s  %s\n' "${_t::6}" "$_t"{,}
  printf -v _f '%%%ds%%%%b\\\\r' {40..10..-2}
  # shellcheck disable=SC2059
  printf -v _f "$_f"
  _f=${_f// /$'\UA0'}
  printf -v _e '%%%%%%ds%%%%%%%%b\\\\U%X\\\\\\\\r' \
      $(( $1 > 16 ? $1 + 917743 : $1 + 65023 ))
  # shellcheck disable=SC2059
  printf -v _e "$_e" {73..43..-2}
  # shellcheck disable=SC2059
  printf -v _e "$_e"
  printf 'Show UTF8 table using: VARIATION SELECTOR-%d (U+%X)\n' "$1" \
      $(( $1 > 16 ? $1 + 917743 : $1 + 65023 ))
  shift
  for _a; do
      printf "$_e${_f}U%03Xyx\n%s" {,}{{F..A..-1},{9..0..-1}} 0x"${_a}" "$_t"
      for _i in {0..9} {A..F}; do
          (( 16#$_a == 0 )) && (( ( 16#$_i & 7 )  < 2 )) &&
          printf 'U%04Xx%68s\n' 0x"$_a$_i" '' && continue
          printf "$_e${_f}U%04Xx\n" \
              "\\U$_a$_i"{,}{{F..A..-1},{9..0..-1}} 0x"$_a$_i"
      done
  done
}

showColorList() {
    for i in $(seq 0 255); do
        # Print foreground color with reset
        printf "\033[38;5;%sm %03s \033[0m" "$i" "$i"
        
        # Add a newline for every 8 colors to format output nicely
        if [ $(( (i + 1) % 8 )) -eq 0 ]; then
            printf "\n"
        fi
    done
    printf "\n"
}

showColorListTput() {
    # Check if the terminal supports colors
    ncolors=$(tput colors)
    if test -n "$ncolors" && test "$ncolors" -ge 8; then
        echo "Displaying basic 8 ANSI colors:"
        for i in 0 1 2 3 4 5 6 7; do
            tput setaf "$i"
            echo "Color $i"
        done
        tput sgr0 # Reset colors

        # Check for 256 color support
        if test "$ncolors" -ge 256; then
            echo ""
            echo "Displaying 256 colors (if supported by your terminal):"
            for i in $(seq 0 255); do
                tput setaf "$i"
                printf "%03d " "$i" # Print color code with leading zeros
                if [ $(( (i + 1) % 16 )) -eq 0 ]; then # Newline every 16 colors for better formatting
                    echo ""
                fi
            done
            echo ""
            tput sgr0 # Reset colors
        fi
    else
        echo "Your terminal does not support 8 or more colors."
    fi
}


if [ "${0##*/}" = "show_icons_table.sh" ]; then
    showU8Variation "$@"
    showColorList
    showColorListTput
fi
