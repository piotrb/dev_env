#!env ruby

packages = `brew list`.split("\n").map(&:strip).sort

safe_packages = %w(rbenv node ruby-build go phantomjs postgresql mysql scala vim tmux zpython wget awscli ghostscript git graphviz libgit2 rbenv-default-gems redis htop libxslt ncdu roll the_platinum_searcher tig yarn openssl@1.1 gradle imagemagick gmp)

threads = []

puts "Launching threads ..."

packages.each do |package|
  next if safe_packages.include?(package)
  threads << Thread.new do
    uses = `brew uses --installed #{package} 2>&1`.strip
    # puts threads.reject { |th| th.status }.length
    print "."
    if $?.success?
      if uses == ""
        { name: package, status: :no_deps }
        # puts "#{package}"
      else
        { name: package, status: :has_deps, uses: uses.split("\n") }
        # we're ok, has some deps
      end
    else
      { name: package, status: :error, error: uses }
      # puts "Err: #{package}: #{uses}"
    end
  end
  sleep 0.1
end

threads.map(&:join)

puts " Done"

threads.each do |thread|
  info = thread.value
  case info[:status]
  when :has_deps
    # ignore
  when :no_deps
    puts "- #{info[:name]}"
  when :error
    puts "Err: #{info[:name]} - #{info[:error]}"
  end
end
