#!/bin/zsh
setopt EXTENDED_GLOB

export AAC_BITRATE=320k

typeset -gx SOURCE_DIR=$1
typeset -gx DEST_DIR=$2

fixm3u() {
  (
    print "Fixing and copy m3u"
    cd $SOURCE_DIR
    for i in */*/*.m3u
    do
      [[ -e $DEST_DIR/$i ]] && continue
      print $DEST_DIR/$i
      perl -p -e 'if (/^[^#]/ && ! /^$/) { tr/!?"\\<>*|:/_________/; s/(\.[a-zA-Z0-9]+)? *$/.m4a/ }' $i >| $DEST_DIR/$i
    done
  )
}

convert_fdkaac() {
  print "Convert AAC with fdkaac..."
  (
    cd $SOURCE_DIR
    for artalbm in */*(#q/)
    do
      oartalbm=$(tr -s '!?\"\\<>*|:' '_' <<< "$artalbm")
      if [[ -e $DEST_DIR/$oartalbm ]]
      then
        if [[ -e "$artalbm/cover.jpg" && ! -e "$DEST_DIR/$oartalbm/cover.jpg" ]]
        then
          print "Album $oartalbm copy cover only." >&2
          cp "$oartalbm/cover.jpg" "$DEST_DIR/$oartalbm/cover.jpg"
          continue
        else
          print "Album $oartalbm is already exist. skipping..." >&2
          continue
        fi
      fi
      mkdir -pv "$DEST_DIR/$oartalbm"
      if [[ -e "$artalbm/cover.jpg" && ! -e "$DEST_DIR/$oartalbm/cover.jpg" ]]
      then
        cp -v "$artalbm/cover.jpg" "$DEST_DIR/$oartalbm/cover.jpg"
      fi
      for song in $artalbm/*.(wav|flac|aiff)
      do
        ffmpeg -nostdin -i "$song" -vn -f wav -c:a pcm_s16le - | fdkaac -b ${AAC_BITRATE} -w 19000 -o "$DEST_DIR/$oartalbm/${${song:t}:r}.m4a" -
        set_id3tag "$song" "$DEST_DIR/$oartalbm/${${song:t}:r}"
      done
    done
  )
}

set_id3tag() {
  print "Copy ID3 Tag......"
  kid3-cli -c 'set title PRE' -c 'save' "$2".m4a
  ruby -r"taglib" - "$1" "$2".m4a <<EOF
TagLib::FileRef.open(ARGV[0]) do |flac|
  TagLib::FileRef.open(ARGV[1]) do |m4a|
    tag = flac.tag
    m4t = m4a.tag
    m4t.artist = tag.artist
    m4t.album = tag.album
    m4t.title = tag.title
    m4t.genre = tag.genre
    m4t.comment = tag.comment
    m4t.track = tag.track
    m4t.year = tag.year
    m4a.save
  end
end
EOF
}

cover4walkman() {
  (
    cd $DEST_DIR
    for i in *
    do
      print For "$i" ...
      (
        cd $i
        for j in *
        do
          if [[ -e $j/cover.jpg && ! -e $j/$j.jpg ]]
          then
            cp -v $j/cover.jpg $j/$j.jpg
          fi
        done
      )
    done
  )
}

if [[ -z $SOURCE_DIR ]]
then
  print SOURCE_DIR is not set.
  exit 1
fi
if [[ -z $DEST_DIR ]]
then
  print DEST_DIR is not set.
  exit 1
fi

print source: $SOURCE_DIR
print dest: $DEST_DIR

convert_fdkaac
fixm3u
cover4walkman
