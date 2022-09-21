#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-
require 'oj'
require 'yaml'
require 'string/similarity'

stored_lines = []

CONFIG = (YAML.load File.read "#{ENV["XDG_CONFIG_DIR"] || "#{ENV["HOME"]}/.config"}/reasonset/reverse-playlist/config.yaml" rescue {})
DB_PATH = "#{ENV["XDG_DATA_DIR"] || "#{ENV["HOME"]}/.local/share"}/reasonset/reverse-playlist/musicdb.json"
DB = Oj.load File.read DB_PATH

playlist = ARGV.shift

albumless = CONFIG["albumless_roots"] || []

class String
  def delsym
    self.downcase.delete("\x00-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F 　")
  end
end

File.foreach(playlist) do |line|
  if line =~ /^#/
    stored_lines.push line
    next
  end

  # Actual file path.
  elms = line.chomp.split("/")
  root = elms[0]
  sqpath = line.chomp.sub(/\.[^\/]+$/, "").delsym
  artist = albumless.include?(elms[0]) ? elms[-2].delsym : elms[-3].delsym
  db = DB[root]
  pathes = db[artist]

  unless pathes
    artist_canditate = db.keys.map {|k| {path: k, score: String::Similarity.cosine(k, artist)} }.sort_by {|i| i[:score]}.reverse[0, 10]
    STDERR.puts "artist #{artist} not found."
    loop do
      artist_canditate.each_with_index do |i, index|
        STDERR.printf "%d. %s (%.3f)\n", index, i[:path], i[:score]
      end
      STDERR.print "?> "
      num = gets
      next unless num =~ /^\d+$/
      artist = artist_canditate[num.to_i]&.[](:path)
      break if artist
    end
    pathes = db[artist]
  end

  path = pathes[sqpath]
  
  unless path
    path_canditate = db[artist].map {|k, v| {path: v, score: String::Similarity.cosine(k, sqpath)} }.sort_by {|i| i[:score]}.reverse
    STDERR.puts "path #{sqpath} not found."
    loop do
      path_canditate.each_with_index do |i, index|
        STDERR.printf "%d. %s (%.3f)\n", index, i[:path], i[:score]
      end
      STDERR.print "?> "
      num = gets
      next unless num =~ /^\d+$/
      path = path_canditate[num.to_i]&.[](:path)
      break if path
    end
  end

  stored_lines.push path
end

puts stored_lines
