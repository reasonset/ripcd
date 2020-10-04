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

fdkaac() {
  print "Convert AAC with libfdk_aac..."
  (
    cd $SOURCE_DIR
    ruby -rfileutils <<EOF
    sources = []
    Dir.glob("*/*").each {|artalbm|
      oartalbm = artalbm.split('/').map {|x| x.tr('!?\"\\<>*|:', '_') }.join("/")
      if File.exist?(%Q%#{ENV['DEST_DIR']}/#{oartalbm}%)
        if File.exist?(%Q%#{artalbm}/cover.jpg%) && ! File.exist?("#{ENV['DEST_DIR']}/#{oartalbm}/cover.jpg")
          FileUtils.cp(%Q%#{artalbm}/cover.jpg%, %Q%#{ENV['DEST_DIR']}/#{oartalbm}/%)
        end
        STDERR.puts "#{artalbm} is already exist. Skipping..."
        next
      else
        FileUtils.mkdir_p(%Q%#{ENV['DEST_DIR']}/#{oartalbm}%)
        if File.exist? %Q%#{artalbm}/cover.jpg%
          FileUtils.cp(%Q%#{artalbm}/cover.jpg%, %Q%#{ENV['DEST_DIR']}/#{oartalbm}/%)
        end
      end
      songfiles = Dir.entries(artalbm).select {|i| File.extname(i) == ".flac" }
      songfiles.sort.each do |songfile|
        params = { source: "#{artalbm}/#{songfile}" }
        params[:dest] = "#{ENV['DEST_DIR']}/#{oartalbm}/#{songfile.tr('!?\"\\<>*|:', '_').sub(/.[a-zA-Z0-9]+$/, '.m4a') }"
        sources.push params
      end
    }
    sources.each { |elm| system('ffmpeg', '-nostdin', '-i', elm[:source], '-c:a', 'libfdk_aac', '-b:a', ENV['AAC_BITRATE'], '-cutoff', '18000', elm[:dest] ) }
EOF
  )
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

fdkaac
fixm3u
cover4walkman
