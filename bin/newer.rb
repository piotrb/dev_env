#!env ruby
require "chronic"

path, newer_than = ARGV

newer_than = Chronic.parse(newer_than)

puts "Looking for #{path.inspect} newer than #{newer_than}"

files = Dir["#{path}/**/*"].select do |f|
  if File.file?(f)
    File.mtime(f) > newer_than
  end
end

files.sort_by! { |f| File.mtime(f) }

g = files.group_by { |f| mt = File.mtime(f); Time.local(mt.year, mt.month, mt.day) }

g.each do |date, files|
  puts "#{date.strftime("%Y-%m-%d")}"
  files.each do |f|
    puts " - #{f}"
  end
end
