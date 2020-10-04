#!/bin/zsh

if [[ -z $RIPCD_OUTDIR ]]
then
  typeset -g RIPCD_OUTDIR=$(xdg-user-dir MUSIC)
fi

print $RIPCD_OUTDIR

print -l $RIPCD_OUTDIR/*/* >| /tmp/ripcd.current
ripit -C gnudb.org -o "$RIPCD_OUTDIR" -D '"$artist/$album"' -c 2 --quality 8
print -l $RIPCD_OUTDIR/*/* >| /tmp/ripcd.next

album=$(diff /tmp/ripcd.current /tmp/ripcd.next | ruby -e 'STDIN.each {|l| l =~ /^> / && print(l[%r:[^/]+/[^/]+$:].sub("/", "-")) && exit }')

if [[ -n "$album" && -e "$album" ]]
then
  perl -pi -e 'if (/^\//) { s@^.*/@@ }' $album/*.m3u
else
  print "NO ALBUM DIRECTORY FOUND." >&2
  exit 2
fi

if [[ -z $RIPCD_IMGDIR ]]
then
  typeset -g RIPCD_IMGDIR=$(xdg-user-dir MUSIC)/rip
fi

[[ -e "$RIPCD_IMGDIR/${album:h}" ]] || mkdir -p "$RIPCD_IMGDIR/${album:h}"
cdrdao read-cd --read-raw --datafile "$RIPCD_IMGDIR/${album}.bin" --driver generic-mmc-raw "$RIPCD_IMGDIR/${album}.toc" && eject

