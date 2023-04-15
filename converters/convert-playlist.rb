#!/bin/ruby
require 'find'

#################################################
# Convert Playlist
# Write fixed playlist ambiguous file path matching.
#################################################
# convert-playlist.rb <SOURCE_DIR> <DEST_DIR>
#################################################
# This is useful when two libraries have difference
# extname (format), file path format (Unix and DOS), e.t.c.
#################################################


SOURCE_DIR = File.expand_path ARGV.shift
DEST_DIR = File.expand_path ARGV.shift

PLAYLISTS = {}

$music_db = {}

if !DEST_DIR || DEST_DIR.empty?
  abort "convert-playlist.rb"
end

Dir.chdir DEST_DIR

playlist_files = []

Find.find(".") do |fp|
  if not %w:.wav .flac .ogg .mp3 .aac .m4a .oga .opus .wma .ra:.include? File.extname fp
    next
  end
  nfp = fp.unicode_normalize(:nfkc).downcase.sub(/\.[^.]+$/, "").delete('!?"\\<>*|:_ -')
  if $music_db[nfp]
    abort "Normalized path name #{nfp} is not unique (assigning #{fp}, already #{$music_db[nfp]})"
  end
  $music_db[nfp] = fp
end

Dir.chdir SOURCE_DIR

playlist_files = Dir.glob("*.m3u")

playlist_files.each do |pfp|
  pfl = []
  File.foreach(pfp) do |line|
    if line =~ /^\s*#/
      pfl.push line
    else
      ptrp = pfp.sub(%r:^./:, "").include?("/") ? (pfp.sub(%r:/[^/]*$:, "") + "/" + line).strip.unicode_normalize(:nfkc).downcase.sub(/\.[^.]+$/, "").delete('!?"\\<>*|:_ -') : line.strip.unicode_normalize(:nfkc).downcase.sub(/\.[^.]+$/, "").delete('!?"\\<>*|:_ -')
      if ptrp !~ %r:^\./:
        ptrp = "./" + ptrp
      end
      ptr_dest = $music_db[ptrp]
      unless ptr_dest
        #pp $music_db
        abort "No match #{line.strip} in #{pfp}"
      end
      pfl.push(ptr_dest + "\n")
    end
  end
  PLAYLISTS[pfp] = pfl.join
end

Dir.chdir DEST_DIR

PLAYLISTS.each do |k, v|
  File.open(k, "w") do |f|
    f.puts v
  end
end
