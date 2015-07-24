#!env ruby
gem 'circleci'
gem 'colorize'
gem 'git'
gem 'uri-ssh_git'
gem 'main'

require 'main'
require 'uri/ssh_git'
require 'circleci'
require 'colorize'
require 'git'
require 'pry'

circle_config = YAML.load_file(File.expand_path('~/.circleci.yml'))

CircleCi.configure do |config|
  config.token = circle_config['token']
end

def fix_ansi(string)
  string.gsub('�', "\033").gsub(/(?!�)(\[\d+m)/, "\033\\1")
end

def print_test(test, index)
  status_color = case test['result']
  when 'skipped'
    :yellow
  when 'failure'
    :red
  else
    :default
  end
  puts "#{index+1}) #{test['source_type']}: #{test['file']}".colorize(status_color)
  print "  #{test['name']} #{test['result']}"
  puts " with:" if test['message']
  puts fix_ansi(test['message']) if test['message']
  puts "\n\n"
end

def build_status(username, repo, build)
  res = CircleCi::Build.tests username, repo, build
  raise "failed" unless res.success?

  skipped_tests = res.body['tests'].select { |test| test['result'] == 'skipped' }
  failed_tests = res.body['tests'].select { |test| test['result'] == 'failure' }

  if skipped_tests.length > 0
    puts "#{skipped_tests.length} tests skipped"
    puts "\n"

    skipped_tests.each_with_index do |test, index|
      print_test(test, index)
    end
  end

  if failed_tests.length > 0
    puts "#{failed_tests.length} tests failed"

    failed_tests.each_with_index do |test, index|
      print_test(test, index)
    end
  end

  # summary

  if failed_tests.length > 0
    puts "Files affected by failures:".colorize(:red)

    failed_tests.group_by { |test| test['source_type'] }.each do |source_type, tests|
      affected_files = tests.map { |test| test['file'] }.uniq
      puts "#{source_type}:"
      affected_files.each do |file|
        puts "  #{file}"
      end
    end
  end
end

def print_build(build)
  status_color = case build['status']
  when 'running' then :yellow
  when 'failed' then :red
  else
    :default
  end
  status_text = (build['status'] == build['outcome']) ? build['status'] : "#{build['status']} (#{build['outcome']})"
  puts "build: #{build['build_num']} - #{status_text} (#{build['lifecycle']})".colorize(status_color)
  # puts "  start time: #{build['start_time']}"
  # start_time = Time.parse(build['start_time'])
end

git_log = Logger.new(STDOUT)
git_log.level = Logger::ERROR
git = Git.open(".", :log => git_log)
origin_url = git.remote('origin').url
url = URI::SshGit.parse(origin_url)

raise "must be inside a github repo" unless url.host == 'github.com'

username, repo = url.path.gsub(/^\//, '').gsub(/\.git$/, '').split('/')
current_branch = git.current_branch

Main {
  mode :list do
    define_method :run do

      res = CircleCi::Project.recent_builds_branch username, repo, current_branch
      raise "failed" unless res.success?

      puts "Branch Builds:".colorize(:yellow)

      res.body.each do |build|
        print_build(build)
      end

    end
  end

  mode :info do
    argument 'build_number'

    define_method :run do
      build = params['build_number'].value
      build_status username, repo, build
    end
  end

  define_method :run do
    help!
  end
}
