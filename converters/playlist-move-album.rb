#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-

# AmazonやDLcvからDLMに移った場合など、Albumの位置が変更になった場合にプレイリストを修正する
# トラックナンバーで始まる形式ならファイル名の揺れも吸収する
# 修正されたプレイリストは_mod_playlistディレクトリに吐かれる
#
# playlist-move-album.rb <SOURCE_ALBUM_DIR> <DEST_ALBUM_DIR>

SOURCE_ALBUM = ARGV.shift
DEST_ALBUM = ARGV.shift

if !SOURCE_ALBUM || SOURCE_ALBUM.empty? || !File.exist?(SOURCE_ALBUM)
  abort "SOURCE ALBUM INVALID"
end

if !DEST_ALBUM || DEST_ALBUM.empty? || !File.exist?(DEST_ALBUM)
  abort "DEST ALBUM INVALID"
end

SONGMAP = {}
SONGMAP_TEMP = {}

Dir.children(SOURCE_ALBUM).each do |i|
  if !File.file?("#{SOURCE_ALBUM}/#{i}") || i !~ /^(\d+)/
    next
  end
  p i
  track = $1.to_i
  SONGMAP_TEMP[track] = {
    source: i
  }
end

Dir.children(DEST_ALBUM).each do |i|
  if !File.file?("#{DEST_ALBUM}/#{i}") || i !~ /^(\d+)/
    next
  end
  track = $1.to_i
  next unless SONGMAP_TEMP[track]
  SONGMAP_TEMP[track][:dest] = i
end

SONGMAP_TEMP.each do |k, v|
  SONGMAP["#{SOURCE_ALBUM}/#{v[:source]}"] = "#{DEST_ALBUM}/#{v[:dest]}"
end

Dir.mkdir("_mod_playlist")

playlists = Dir.children(".").select {|i| i[-4, 4] == ".m3u" }
playlists.each do |fn|
  mod = false
  lines = []
  File.foreach(fn) do |line|
    if line.include? SOURCE_ALBUM
      mod = true
      path = line.chomp
      if !SONGMAP[path]
        abort "#{path} is not exist."
      end
      line = SONGMAP[path]
    end
    lines.push line
  end
  if mod
    File.open("_mod_playlist/#{fn}", "w") do |f|
      f.puts lines
    end
  end
end
