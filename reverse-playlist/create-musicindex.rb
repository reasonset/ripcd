#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-
require 'find'
require 'yaml'
require 'oj'

db = Hash.new do |h, k|
  h[k] = Hash.new do |h2, k2|
    h2[k2] = {}
  end
end

AUDIO_EXTS = %w:wav flac m4a mp3 aac ogg oga opus rm wma:.map {|i| "." + i}
CONFIG = (YAML.load File.read "#{ENV["XDG_CONFIG_DIR"] || "#{ENV["HOME"]}/.config"}/reasonset/ripcd/reverse-playlist.yaml" rescue {})

DB_PATH = "#{ENV["XDG_DATA_DIR"] || "#{ENV["HOME"]}/.local/share"}/reasonset/ripcd/musicdb.json"

flatroot = CONFIG["flat_roots"] || []
albumless = CONFIG["albumless_roots"] || []

class String
  def delsym
    self.downcase.unicode_normalize(:nfkc).delete("\x00-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F 　")
  end
end

Find.find(*Dir.children(".").select {|i| File.directory? i}.map {|i| i + "/"}) do |fpath|
  ext = File.extname fpath
  next unless AUDIO_EXTS.include? ext
  elms = fpath.split("/")
  root = elms[0]
  artist = case 
  when flatroot
    elms[0].delsym
  when albumless.include?(elms[0]) || elms.length == 2
    elms[-2].delsym
  else 
    elms[-3].delsym
  end
  sq = fpath.sub(/\.[^\/]+$/, "").delsym
  db[root][artist][sq] = fpath
  STDERR.printf("%s: %s => %s\n", artist, sq, fpath)
end

File.open(DB_PATH, "w") do |f|
  f.write Oj.dump db
end
