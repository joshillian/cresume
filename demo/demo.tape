# Regenerate README screenshots:  vhs demo/demo.tape   (run from repo root)
# Uses a throwaway $HOME seeded with fake sessions by demo/seed.py.
Output demo/cresume.gif

Set Shell zsh
Set FontSize 14
Set Width 1640
Set Height 540
Set Padding 18
Set Theme "Catppuccin Mocha"
Set TypingSpeed 70ms

Hide
Type "export H=$(mktemp -d) && python3 demo/seed.py $H && exec env HOME=$H ZDOTDIR=$H CRESUME_CMD='echo claude' PLUGIN=$PWD/cresume.plugin.zsh zsh -f"
Enter
Sleep 1s
Type "PROMPT='%F{141}%~%f %F{208}❯%f '; source $PLUGIN; cd ~; clear"
Enter
Sleep 500ms
Show

Type "cresume"
Sleep 400ms
Enter
Sleep 2.5s
Screenshot demo/picker.png
Sleep 300ms
Down
Sleep 700ms
Down
Sleep 1s
Type "web"
Sleep 1.2s
Screenshot demo/filter.png
Sleep 300ms
Down
Sleep 1s
Enter
Sleep 2.5s
