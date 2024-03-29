#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-
require 'oj'
require 'yaml'
require 'string/similarity'

stored_lines = []

CONFIG = (YAML.load File.read "#{ENV["XDG_CONFIG_DIR"] || "#{ENV["HOME"]}/.config"}/reasonset/ripcd/reverse-playlist.yaml" rescue {})
DB_PATH = "#{ENV["XDG_DATA_DIR"] || "#{ENV["HOME"]}/.local/share"}/reasonset/ripcd/musicdb.json"
DB = Oj.load File.read DB_PATH

playlist = ARGV.shift

flatroot = CONFIG["flat_roots"] || []
albumless = CONFIG["albumless_roots"] || []

class String
  def delsym
    self.downcase.unicode_normalize(:nfkc).delete("\x00-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F 　")
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
  artist = case 
  when flatroot
    elms[0].delsym
  when albumless.include?(elms[0]) || elms.length == 2
    elms[-2].delsym
  else 
    elms[-3].delsym
  end
  db = DB[root]
  abort "Root #{root} is not exist." unless db
  pathes = db[artist]

  unless pathes
    artist_canditate = db.keys.map {|k| {path: k, score: String::Similarity.cosine(k, artist)} }.sort_by {|i| i[:score]}.reverse[0, 10]
    STDERR.puts "artist #{artist} not found."
    loop do
      artist_canditate.each_with_index do |i, index|
        STDERR.printf "%d. %s (%.3f)\n", index, i[:path], i[:score]
      end
      STDERR.puts "m. Manual Input"
      STDERR.print "?> "
      num = gets
      if num =~ /^[Mm]$/
        STDERR.print "Artist?> "
        artist = gets.chomp.delsym
        break if db[artist]
      else
        next unless num =~ /^\d+$/
        artist = artist_canditate[num.to_i]&.[](:path)
        break if artist
      end
    end
    pathes = db[artist]
  end

  path = pathes[sqpath]
  
  unless path
    path_canditate = db[artist].map {|k, v| {path: v, score: String::Similarity.cosine(k, sqpath)} }.sort_by {|i| i[:score]}.reverse[0, 30]
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
