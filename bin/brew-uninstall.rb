#!env ruby
leaves = `brew leaves`.split("\n").map(&:strip)
p leaves
p ARGV
system ["brew uninstall", *ARGV].join(" ")
after_leaves = `brew leaves`.split("\n").map(&:strip)
new_leaves = after_leaves - leaves
p new_leaves
