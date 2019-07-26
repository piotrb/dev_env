#!env ruby

def sh(command)
  system(command) || exit($?.status)
end

puts "Convering images into an initial pdf ..."

input_files = ARGV.map { |file| file.inspect }.join(" ")

sh "convert \
    -depth 100 \
    -units PixelsPerInch \
    -resize 850X1100 \
    -density 100 \
    -auto-orient \
    #{input_files} output.pdf"

puts "Converting to ps ..."

sh "pdf2ps output.pdf output.ps"

puts "Converting back to pdf ..."

sh "ps2pdf output.ps output.pdf"

File.unlink("output.ps")

puts "Done"
