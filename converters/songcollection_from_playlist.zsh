#!/bin/zsh

###########################################
# Song Collection from Playlist
# Copy playlist and tracks in playlist
###########################################
# songcollection_from_playlist.zsh <DEST_DIR>
###########################################


DEST_DIR="$1"

if [[ -z $DEST_DIR ]]
then
  print "songcollection_from_playlist.zsh <DEST_DIR>"
  exit 1
fi

shift


for i in *.m3u
do
  sed '/^#/ d' $i | while read track
  do
    if [[ $track[0] == / ]]
    then
      print "Track $i is absolute in $i"
    elif [[ ! -e "$DEST_DIR/$track" ]]
    then
      [[ -e "$DEST_DIR/${track:h}" ]] || mkdir -p "$DEST_DIR/${track:h}"
      cp "$track" "$DEST_DIR/$track"
    fi
  done
  cp "$i" "$DEST_DIR"
done