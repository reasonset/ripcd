#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-
require 'yaml'

toc_lines = []

CONFIG = YAML.load File.read "#{ENV["XDG_CONFIG_DIR"] || "#{ENV["HOME"]}/.config"}/reasonset/ripcd/expand-playlist.yaml"

artist_dic = (YAML.load File.read "#{ENV["XDG_CONFIG_DIR"] || "#{ENV["HOME"]}/.config"}/reasonset/ripcd/artist-dic.yaml" rescue {})

expand_dir = CONFIG["dir"]

if !expand_dir || expand_dir.empty?
  abort "DIR is not present."
end

# Setup Kakasi
kakasi_command = %w:kakasi -Ja -Ha -Ka -s -i utf-8 -o utf-8:
kakasi_command.push CONFIG["kakasi_dic"] if CONFIG["kakasi_dic"]

toc_lines << %!CD_DA!
if CONFIG["use_cdtext"]
  toc_lines << %!CD_TEXT {!
  toc_lines << %!  LANGUAGE_MAP {!
  toc_lines << %!    0 : EN!
  toc_lines << %!  }!
  toc_lines << %!!
  toc_lines << %!  LANGUAGE 0 {!
  toc_lines << %!    TITLE "#{File.basename((ARGV[0] || ""), ".*")}"!
  toc_lines << %!    PERFORMER "Various Artist"!
  toc_lines << %!  }!
  toc_lines << %!}!
end
toc_lines << %!!

ARGF.each do |line|
  next if line =~ /^#/
  source = line.chomp
  title = IO.popen(["kid3-cli", "-c", "get title 2", source]) {|io| io.read.strip }
  performer = IO.popen(["kid3-cli", "-c", "get artist 2", source]) {|io| io.read.strip }
  performer_completed = false

  if artist_dic[performer]
    performer = artist_dic[performer]
    performer_completed = true
  end

  if CONFIG["use_kakasi"]
    title = IO.popen(kakasi_command, "w+") do |io|
      io.print title
      io.close_write
      io.read.strip
    end
    unless performer_completed
      performer = IO.popen(kakasi_command, "w+") do |io|
        io.print performer
        io.close_write
        io.read.strip
      end
    end
  end

  outfile = File.basename(source, ".*") + ".wav"

  system("ffmpeg", "-nostdin", "-i", source, "-ac", "2", "-ar", "44100", "#{expand_dir}/#{outfile}")
  
  toc_lines << %:TRACK AUDIO:
  if CONFIG["use_cdtext"]
    toc_lines << %:  CD_TEXT {:
    toc_lines << %:    LANGUAGE 0 {:
    toc_lines << %:      TITLE "#{title.delete('"') rescue title}":
    toc_lines << %:      PERFORMER "#{performer.delete('"') rescue performer}":
    toc_lines << %:    }:
    toc_lines << %:  }:
  end
  toc_lines << %:  FILE "#{outfile}" 0:
  toc_lines << %::
end

File.open("#{expand_dir}/playlist.toc", "w") {|f| f.puts toc_lines}