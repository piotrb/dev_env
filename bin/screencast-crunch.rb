#!env ruby

def output_path(input)
  ext = File.extname(input)
  base_name = input[0..(-1 * (ext.length + 1))]
  "#{base_name} (compressed)#{ext}"
end

input = ARGV[0]
output = output_path(input)

#system "ffmpeg -i #{input.inspect} -vf scale=960:-1 -vcodec h264 -crf 30 -absf noise -ab 32 #{output.inspect}"
system "ffmpeg -i #{input.inspect} -vf scale=960:-1 -vcodec h264 -crf 30 #{output.inspect}"
