#!/bin/ruby
require 'yaml'

CONFIG = File.exist?("#{ENV["XDG_CONFIG_DIR"] || "#{ENV["HOME"]}/.config"}/reasonset/ripcd/normalize-wav4cd.yaml") ? YAML.load(File.read "#{ENV["XDG_CONFIG_DIR"] || "#{ENV["HOME"]}/.config"}/reasonset/ripcd/normalize-wav4cd.yaml") : {}

files = ARGV.dup
if files.empty?
  files = Dir.glob("*.wav")
end

current_step = 0

puts "==============> BOOST GAIN TO LIMIT"
current_step += 1
Dir.mkdir("step#{current_step}")
files.each do |i|
  IO.popen(["ffmpeg", "-i", i, "-vn", "-af", "volumedetect", "-f", "null", "-"], err: [:child, :out]) do |io|
    result = io.read
    result =~ /max_volume: (-?[0-9.]+) dB/
    db = $1.to_f
    if db <= -0.1
      puts "#{i} is not reach 0.0dB (#{db}dB), increase gain."
      system("ffmpeg", "-i", i, "-vn", "-af", ("volume=%.1fdB" % db.abs), "step#{current_step}/#{i}")
    else
      system("cp", i, "step#{current_step}/#{i}")
    end
  end
end

puts "==============> CHECKING LUFS"
boost = files.select do |i|
  IO.popen(["ffmpeg", "-i", "step#{current_step}/#{i}", "-vn", "-af", "ebur128", "-f", "null", "-"], err: [:child, :out]) do |io|
    stat = false
    while line = io.gets
      break if line.include?("Integrated loudness")
    end
    io.each do |line|
      if line =~ /^\s*I:\s*(-?\d+\.\d+) LUFS/
        lufs = $1.to_f
        stat = lufs < -12
        break
      end
    end
    next stat
  end
end

if boost.empty?
  puts "NO BOOST FILES"
else
  puts "These files will be to boost"
  puts boost
end

unless CONFIG["NO_COMPRESS_SPIKE"]
  current_step += 1
  puts "==============> COMPRESS SPIKE"
  Dir.mkdir("step#{current_step}")
  files.each do |i|
    if boost.include? i
      max_gain = 100
      IO.popen(["ffmpeg", "-i", "step#{current_step - 1}/#{i}", "-vn", "-af", "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level", "-f", "null", "-"], err: [:child, :out]) do |io|
        io.each do |line|
          next unless line.include?("lavfi.astats.Overall.RMS_level")
          if line =~ /lavfi.astats.Overall.RMS_level=-?(\d+.\d+)/
            level = $1.to_f
            next if level < 8
            max_gain = level if level < max_gain
          end
        end
      end
      system("ffmpeg", "-i", "step#{current_step - 1}/#{i}", "-vn", "-af", ("acompressor=threshold=-%.1fdB:ratio=20:attack=0.1:release=20" % max_gain.abs), "step#{current_step}/#{i}")
    else
      system("cp", "step#{current_step - 1}/#{i}", "step#{current_step}/#{i}")
    end
  end

  current_step += 1
  Dir.mkdir("step#{current_step}")
  files.each do |i|
    if boost.include? i
      IO.popen(["ffmpeg", "-i", i, "-vn", "-af", "volumedetect", "-f", "null", "-"], err: [:child, :out]) do |io|
        result = io.read
        result =~ /max_volume: (-?[0-9.]+) dB/
        db = $1.to_f
        if db <= -0.1
          system("ffmpeg", "-i", "step#{current_step - 1}/#{i}", "-vn", "-af", ("volume=%.1fdB" % db.abs), "step#{current_step}/#{i}")
        else
          system("cp", "step#{current_step - 1}/#{i}", "step#{current_step}/#{i}")
        end
      end
    else
      system("cp", "step#{current_step - 1}/#{i}", "step#{current_step}/#{i}")
    end
  end
end

unless CONFIG["NO_COMPRESSION"]
  current_step += 1
  puts "==============> COMPRESS MEAN"
  Dir.mkdir("step#{current_step}")
  files.each do |i|
    if boost.include? i
      mean = 0
      IO.popen(["ffmpeg", "-i", "step#{current_step - 1}/#{i}", "-vn", "-af", "volumedetect", "-f", "null", "-"], err: [:child, :out]) do |io|
        result = io.read
        result =~ /mean_volume: (-?[0-9.]+) dB/
        mean = $1.to_f
      end
      system("ffmpeg", "-i", "step#{current_step - 1}/#{i}", "-vn", "-af", ("acompressor=threshold=-%.1fdB:ratio=9:attack=0.1:release=200" % mean.abs), "step#{current_step}/#{i}")
    else
      system("cp", "step#{current_step - 1}/#{i}", "step#{current_step}/#{i}")
    end
  end

  current_step += 1
  Dir.mkdir("step#{current_step}")
  files.each do |i|
    if boost.include? i
      IO.popen(["ffmpeg", "-i", i, "-vn", "-af", "volumedetect", "-f", "null", "-"], err: [:child, :out]) do |io|
        result = io.read
        result =~ /max_volume: (-?[0-9.]+) dB/
        db = $1.to_f
        if db <= -0.1
          system("ffmpeg", "-i", "step#{current_step - 1}/#{i}", "-vn", "-af", ("volume=%.1fdB" % db.abs), "step#{current_step}/#{i}")
        else
          system("cp", "step#{current_step - 1}/#{i}", "step#{current_step}/#{i}")
        end
      end
    else
      system("cp", "step#{current_step - 1}/#{i}", "step#{current_step}/#{i}")
    end
  end
end


unless CONFIG["NO_NORMALIZATION"]
  puts "==============> LOUDNESS NORMALIZATION"
  current_step += 1
  Dir.mkdir("step#{current_step}")
  system("ffmpeg-normalize", *(files.map {|i| "step#{current_step - 1}/#{i}" }), "-ar", "44100", "--keep-loudness-range-target", "-o", *(files.map {|i| "step#{current_step}/#{i}" }))

  puts "==============> BOOST TO LIMIT BASED ON NORMALIZATION"
  max_volume = -99.9
  current_step += 1
  Dir.mkdir("step#{current_step}")
  files.each do |i|
    IO.popen(["ffmpeg", "-i", "step#{current_step - 1}/#{i}", "-vn", "-af", "volumedetect", "-f", "null", "-"], err: [:child, :out]) do |io|
      result = io.read
      result =~ /max_volume: (-?[0-9.]+) dB/
      db = $1.to_f
      if db > max_volume
        max_volume = db
      end
    end
  end
  puts "==============> BOOST GAIN - #{max_volume}"

  files.each do |i|
    if max_volume > -0.1
      system("cp", "-v", "step#{current_step - 1}/#{i}", "step#{current_step}/#{i}")
    else
      system("ffmpeg", "-i", "step#{current_step - 1}/#{i}", "-vn", "-af", ("volume=%.1fdB" % max_volume.abs), "step#{current_step}/#{i}")
    end
  end
end

puts "==============> OVERWRITE WITH NORMALIZED AUDIO"
files.each do |i|
  system("mv", "-v", "step#{current_step}/#{i}", "./")
end

puts "==============> CLEAN UP"
system("rm", "-rv", *((1 .. current_step).map {|i| "step#{i}"}))
