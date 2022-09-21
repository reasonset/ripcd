#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-

# require 'taglib'
#
# TagLib::FileRef.open(ARGV[0]) do |flac|
#   TagLib::FileRef.open(ARGV[1]) do |m4a|
#     tag = flac.tag
#     m4t = m4a.tag
#     m4t.artist = tag.artist
#     m4t.album = tag.album
#     m4t.title = tag.title
#     m4t.genre = tag.genre
#     m4t.comment = tag.comment
#     m4t.track = tag.track
#     m4t.year = tag.year
#     m4a.save
#   end
# end
#

OUTDIR = "#{ENV['HOME']}/tmp"

lines = []

# PRE
lines.push("CD_DA")
lines.push("")

ARGV.each_with_index do |i, index|
  lines.push("// Track #{index + 1}")
  lines.push("TRACK AUDIO")
  lines.push("NO COPY")
  lines.push("NO PRE_EMPHASIS")
  lines.push("TWO_CHANNEL_AUDIO")
  lines.push('ISRC "X00000000000"')
  dest_file_name = sprintf('%02d-%s.wav', (index + 1), i.sub(/.*\//, "").sub(/\.[^.]*$/, ""))
  system("ffmpeg", "-i", i, "-ac", "2", "-ar", "44100", "#{OUTDIR}/#{dest_file_name}")
  duration_str = %x:soxi -d "#{OUTDIR}/#{dest_file_name}":.sub(/^\d\d:/, "").sub(".", ":")
  lines.push(sprintf('FILE "%s" 0 %s', "#{OUTDIR}/#{dest_file_name}", duration_str))
  lines.push("")
  lines.push("")
end

puts lines
