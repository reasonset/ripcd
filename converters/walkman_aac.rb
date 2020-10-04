#!/usr/bin/ruby

SOURCE_DIR = ARGV.shift
DEST_DIR = ARGV.shift

unless SOURCE_DIR && DEST_DIR
  abort "walkman_aac.rb <source_dir> <dest_dir>"
end

def fixm3u
  puts "Fixing and copy m3u..."
  Dir.chdir(SOURCE_DIR)
  Dir.glob("*/*/*.m3u").each do |m3u|
    next if File.exist?("#{DEST_DIR}/#{m3u}")
    File.open(m3u, "r") do |rf|
      File.open("#{DEST_DIR}/#{m3u}", "w") do |wf|
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

def fdkaac
  puts "Convert AAC with libfdk_aac..."
  Dir.chdir(SOURCE_DIR)
  Dir.glob("*/*").each do |artalbm|
    if File.exist? "#{DEST_DIR}/#{artalbm}"
      puts "#{artalbm} is exist. Skipping..."
      next
    end
    Dir.foreach(artalbm) do |filename|
      outfilename = filename.tr('!?\"\\<>*|:', '_').sub(/.[a-zA-Z0-9]+$/, '.m4a')
      
    end
  end
end
