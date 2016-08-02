#!env ruby

filename = ARGV[0]

require 'yaml'
require 'fileutils'

def sh(cmd)
  puts "$: #{cmd}"
  system(cmd) || raise("failed")
end

def rm(fn)
  puts "rm: #{fn}"
  File.unlink(fn)
end

def mv(src, dst)
  puts "mv: #{src} -> #{dst}"
  FileUtils.mv(src, dst)
end

appname = filename.split('.').first
dbtime = Time.at(filename.split('.').find { |i| i =~ /^\d+$/ }.to_i)

dbname = "#{appname}_prod_#{dbtime.strftime("%Y_%m_%d")}"

sql = "drop database if exists #{dbname};"
sh("echo #{sql.inspect} | mysql -u dev -pdev")

sql = "create database #{dbname};"
sh("echo #{sql.inspect} | mysql -u dev -pdev")

puts "updating database.yml"
File.open('config/database.yml.new', 'w') { |fh|
  data = YAML.load_file('config/database.yml.example')
  data['development']['database'] = dbname
  fh.write data.to_yaml
}

rm('config/database.yml') if File.exist?('config/database.yml')
mv('config/database.yml.new', 'config/database.yml')

sh "rake db:schema:load"

sh "pv -w 80 -cN raw_data #{filename.inspect} | gunzip -c | pv -w 80 -cN uncompressed | mysql -u dev -pdev #{dbname.inspect}"
