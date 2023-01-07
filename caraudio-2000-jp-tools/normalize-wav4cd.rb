#!/bin/ruby

files = ARGV.dup
if files.empty?
  files = Dir.glob("*.wav")
end

puts "==============> BOOST GAIN TO LIMIT"
Dir.mkdir("step1")
files.each do |i|
  IO.popen(["ffmpeg", "-i", i, "-vn", "-af", "volumedetect", "-f", "null", "-"], err: [:child, :out]) do |io|
    result = io.read
    result =~ /max_volume: (-?[0-9.]+) dB/
    db = $1.to_f
    if db <= -0.2
      target = db + 0.1
      puts "#{i} is not reach 0.0dB (#{db}dB), increase gain #{target.abs}"
      system("ffmpeg", "-i", i, "-vn", "-af", ("volume=%.1fdB" % target.abs), "step1/#{i}")
    else
      system("cp", i, "step1/#{i}")
    end
  end
end

puts "==============> LOUDNESS NORMALIZATION"
Dir.mkdir("step2")
#system("ffmpeg-normalize", *(files.map {|i| "step1/#{i}" }), "-ar", "44100", "--keep-loudness-range-target", "-o", *(files.map {|i| "step2/#{i}" }))
system("ffmpeg-normalize", *(files.map {|i| "step1/#{i}" }), "-ar", "44100", "-o", *(files.map {|i| "step2/#{i}" }))

puts "==============> BOOST TO LIMIT BASED ON NORMALIZATION"
max_volume = -99.9
Dir.mkdir("step3")
files.each do |i|
  IO.popen(["ffmpeg", "-i", "step2/#{i}", "-vn", "-af", "volumedetect", "-f", "null", "-"], err: [:child, :out]) do |io|
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
  system("ffmpeg", "-i", "step2/#{i}", "-vn", "-af", ("volume=%.1fdB" % (max_volume.abs - 0.1)), "step3/#{i}")
end

puts "==============> OVERWRITE WITH NORMALIZED AUDIO"
files.each do |i|
  system("mv", "-v", "step3/#{i}", "./")
end

puts "==============> CLEAN UP"
system("rm", "-rv", "step1", "step2", "step3")
