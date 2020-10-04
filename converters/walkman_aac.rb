#!/usr/bin/ruby
require 'fileutils'

AAC_BITRATE = "320k"

SOURCE_DIR = ARGV.shift
DEST_DIR = ARGV.shift

unless SOURCE_DIR && DEST_DIR && File.exist?(SOURCE_DIR) && File.exist?(DEST_DIR)
  abort "walkman_aac.rb <source_dir> <dest_dir>"
end

$artalbm_list = []
Dir.chdir(SOURCE_DIR)
Dir.glob("*/*").each do |artalbm|
  params = { source: artalbm }
  params[:dest_ary] = ["#{ENV['DEST_DIR']}", artalbm.split('/').map {|x| x.tr('!?\"\\<>*|:', '_') }]
  params[:dest] = params[:dest_ary].join("/")
  params[:exist] = File.exist?("#{ENV['DEST_DIR']}/#{oartalbm}")
  params[:cover] = File.exist?(%Q%#{artalbm}/cover.jpg%) && %Q%#{artalbm}/cover.jpg%
  params[:cover_exist] = File.exist?("#{ENV['DEST_DIR']}/#{oartalbm}/cover.jpg")
  m3u = Dir.entries(artalbm).select {|i| File.extname(i) == ".m3u" }
  params[:m3u] == m3u.empty? ? nil : m3u.first
  $artalbm_list.push params
end

def fixm3u
  puts "Fixing and copy m3u..."
  Dir.chdir(SOURCE_DIR)
  $artalbm_list.each do |i|
    if i[:m3u] && ! File.exist?("#{i[:dest]}/#{i[:dest_ary[2]]}.m3u")
      File.open(i[:m3u], "r") do |rf|
        File.open("#{i[:dest]}/#{i[:dest_ary[2]]}.m3u", "w") do |wf|
          rf.each do |line|
            if (line =~ /^[^#]/ && line !~ /^$/)
              wf.print line.tr(%q{!?"\\<>*|:}, '_').sub(/(?:\.[a-zA-Z0-9]+)? *$/, ".m4a")
            else
              wf.print line
            end
          end
        end
      end
    end
  end
end

def fdkaac
  puts "Convert AAC with libfdk_aac..."
  Dir.chdir(SOURCE_DIR)

  sources = []
  $artalbm_list.each do |i|
    FileUtils.mkdir_p(i[:dest]) unless i[:exist]
    if i[:cover] && ! i[:cover_exist]
      FileUtils.cp(i[:cover], "#{i[:dest]}/cover.jpg")
    end
    if i[:exist]
      STDERR.puts "#{i[:source]} is already exist. Skipping..."
      next
    end
    songfiles = Dir.entries(i[:source]).select {|i| File.extname(i) == ".flac" }
    songfiles.sort.each do |songfile|
      params = { source: "#{i[:source]}/#{songfile}" }
      params[:dest] = "#{i[:dest]}/#{songfile.tr('!?\"\\<>*|:', '_').sub(/.[a-zA-Z0-9]+$/, '.m4a') }"
      sources.push params
    end
  end
  sources.each { |elm| system('ffmpeg', '-nostdin', '-i', elm[:source], '-c:a', 'libfdk_aac', '-b:a', AAC_BITRATE, '-cutoff', '18000', elm[:dest] ) }
end

def cover4walkman
  Dir.chdir(ENV['DEST_DIR'])
  Dir.foreach(".") do |artist|
    next if artist[0] == "."
    puts "For #{artist}..."

    Dir.foreach(artist) do |album|
      next if album[0] == "."

      if File.exist?("#{artist}/#{album}/cover.jpg") && ! File.exist?("#{artist}/#{album}/#{album}.jpg")
        FileUtils.cp("#{artist}/#{album}/cover.jpg", "#{artist}/#{album}/#{album}.jpg")
      end
    end
  end
end

fdkaac
fixm3u
cover4walkman
