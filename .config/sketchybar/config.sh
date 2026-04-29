sketchybar --bar height=12 padding_left=6 padding_right=6
sketchybar --bar font="SF Pro Text:Regular:12"
sketchybar --add item battery right \
           --set battery update_freq=30 \
                         icon="🔋" \
                         label_color=0xfff5f5f5 \
                         icon_color=0xfff5f5f5
sketchybar --add item wifi right \
           --set wifi update_freq=10 \
                     icon="📶" \
                     script="$HOME/.config/sketchybar/scripts/wifi.sh"

