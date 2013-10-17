#!/usr/bin/env ruby

fn = ARGV[0]

ext = File.extname(fn)
raise "only supports .erb files" unless ext == ".erb"

dst_fn = fn.gsub(/\.erb$/, '.haml')

cmd = "html2haml -e #{fn.inspect} #{dst_fn.inspect}"
system cmd
raise "failed" unless $?.success?

puts "#{fn} Removed"
File.unlink(fn)
