#!/usr/bin/zsh --no-glob-dots
setopt nullglob

#Output dirs.
typeset sounddir=~/local/pub/media/sound/music/fromCD/flac
typeset cddir=~/archive/single/CD

#Rip.
pushd $sounddir
list1="$(print -l */*)"
#print "list1::\n" $list1 #DEBUG
ripit --thread 4 -o ./ -c 2 -C freedb.org --dirtemplate '"$artist/$album"' -T '"$tracknum-$trackname"' -q 8 $opts
list2="$(print -l */*)"
#print "list2::\n" $list2 #DEBUG

# Get new directory (Artist/Album)
label="$( print -nl $list1 $list2 | sort | uniq -u | head -n 1 )"
artist="${label:h}"
album="${label:t}"

#print label = $label # DEBUG
popd

# Encode to OggVorbis
print -l  "$sounddir/$artist/$album/"*.flac | xargs -P 2 -d '\n' oggenc -b 192
mkdir -p "${sounddir/flac/ogg}/$artist/$album"
mv "$sounddir/$artist/$album/"*.ogg "${sounddir/flac/ogg}/$artist/$album/"

# Treat invalid filename.
for i in ${soundsir:h}/*/$artist/$album/*[?:]*.*
do
  if [[ -z $i ]]; then break; fi
  mv "$i" "${i//[?!:#*]/}"
done

#Prepare CD image dir.
cddir="$cddir/${artist}"
#print Dir: $outdir #DEBUG
if [[ ! -e $dir ]]
then
  mkdir -p "$cddir"
fi

#Copy.
cdrdao read-cd --read-raw --datafile $cddir/$album.bin --driver generic-mmc-raw $cddir/$album.toc
eject
