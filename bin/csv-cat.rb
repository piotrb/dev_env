#!env ruby
require 'terminal-table'
require 'csv'

table = Terminal::Table.new

CSV.read(ARGV[0]).each_with_index do |row, index|
  if index == 0
    table.headings = row
  else
    table << row
  end
end

puts table
