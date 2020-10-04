#!/bin/zsh

######
# walkman_setcovername.zsh <base_directory>
######

DEST_DIR=$1

if [[ -z "$DEST_DIR" || ! -e "$DEST_DIR" ]]
then
  print Base directory is not given. >&2
  exit 1
else
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
fi
