#!/bin/zsh
setopt EXTENDED_GLOB
setopt BARE_GLOB_QUAL

if [[ ${XDG_CONFIG_DIR:-$HOME/.config}/reasonset/ripcd.zsh ]]
then
  source ${XDG_CONFIG_DIR:-$HOME/.config}/reasonset/ripcd.zsh
fi

if [[ -z $RIPCD_OUTDIR ]]
then
  typeset -g RIPCD_OUTDIR=$(xdg-user-dir MUSIC)
fi

print $RIPCD_OUTDIR
cd $RIPCD_OUTDIR

# Get albums before rip.
print -l */*(/) > /tmp/ripcd.$$.current

# rip
ripit -C gnudb.org -o "$RIPCD_OUTDIR" -D '"$artist/$album"' -c 2 --quality 8

# Get albums after rip.
print -l */*(/) > /tmp/ripcd.$$.next

album_list=(${(f)"$(sort /tmp/ripcd.$$.current /tmp/ripcd.$$.next | uniq -u)"})

if (( ${#album_list} == 1 ))
then
  album="${album_list[1]}"
else

  select album in $album_list "Manual Input"
  do
    if [[ -n "$album" && -e "$album" ]]
    then
      perl -pi -e 'if (/^\//) { s@^.*/@@ }' $album/*.m3u
      break
    elif [[ "$album" == "Manual Input" ]]
    then
      read "album?artist/album-> "
      if [[ -n "$album" && -e "$album" ]]
      then
        perl -pi -e 'if (/^\//) { s@^.*/@@ }' $album/*.m3u
        break
      else
        print "NO ALBUM DIRECTORY FOUND." >&2
      fi
    else
      print "NO ALBUM DIRECTORY FOUND." >&2
    fi
  done
fi


if [[ -z $RIPCD_IMGDIR ]]
then
  typeset -g RIPCD_IMGDIR=$(xdg-user-dir MUSIC)/rip
fi

[[ -e "$RIPCD_IMGDIR/${album:h}" ]] || mkdir -p "$RIPCD_IMGDIR/${album:h}"
cdrdao read-cd --read-raw --datafile "$RIPCD_IMGDIR/${album}.bin" --driver generic-mmc-raw "$RIPCD_IMGDIR/${album}.toc" && eject

