#!env ruby
gem 'circleci'
gem 'colorize'
gem 'git'
gem 'uri-ssh_git'
gem 'commander'
gem 'time_diff'
gem 'descriptive-statistics'

require 'descriptive-statistics'
require 'commander'
require 'time_diff'
require 'uri/ssh_git'
require 'circleci'
require 'colorize'
require 'git'
require 'pry'

require 'yaml'

circle_config = YAML.load_file(File.expand_path('~/.circleci.yml'))

CircleCi.configure do |config|
  config.token = circle_config['token']
end

class TestInfo
  class << self
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

    private

    def fix_ansi(string)
      string.gsub('�', "\033").gsub(/(?!�)(\[\d+m)/, "\033\\1")
    end
  end
end

class BuildInfo
  class << self

    def build_status(username, repo, build)
      res = CircleCi::Build.tests username, repo, build
      raise "failed" unless res.success?

      skipped_tests = res.body['tests'].select { |test| test['result'] == 'skipped' }
      failed_tests = res.body['tests'].select { |test| test['result'] == 'failure' }

      if skipped_tests.length > 0
        puts "#{skipped_tests.length} tests skipped"
        puts "\n"

        skipped_tests.each_with_index do |test, index|
          TestInfo.print_test(test, index)
        end
      end

      if failed_tests.length > 0
        puts "#{failed_tests.length} tests failed"

        failed_tests.each_with_index do |test, index|
          TestInfo.print_test(test, index)
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

  end
end

def print_build(build)
  status_color = :default
  status_color = :yellow if build['status'] == 'running'
  status_color = :red if build['status'] == 'failed'
  status_color = :green if build['outcome'] == 'success'

  status_text = []
  status_text << "build: #{build['build_num']} -"
  status_text << ((build['status'] == build['outcome'] || build['outcome'].nil?) ? build['status'] : "#{build['status']} -> #{build['outcome']}")
  status_text << "(#{build['lifecycle']})" if build['lifecycle'] != 'finished' && build['lifecycle'] != build['status']

  puts status_text.join(' ').colorize(status_color)
  # puts "  start time: #{build['start_time']}"
  # start_time = Time.parse(build['start_time'])
end

class GitInfo
  def initialize(path: '.')
    git_log = Logger.new(STDOUT)
    git_log.level = Logger::ERROR
    @git = Git.open(".", :log => git_log)
  end

  def origin_url
    origin_url = @git.remote('origin').url
    URI::SshGit.parse(origin_url)
  end

  def username
    parse_origin[0]
  end

  def repo
    parse_origin[1]
  end

  def current_branch
    @git.current_branch
  end

  def ensure_github!
    raise "must be inside a github repo" unless origin_url.host == 'github.com'
  end

  private

  def parse_origin
    username, repo = origin_url.path.gsub(/^\//, '').gsub(/\.git$/, '').split('/')
    [username, repo]
  end
end

class CircleCLI
  include Commander::Methods

  def format_ms(ms)
    return "-" if ms.nil?
    sec = ms / 1000
    Time.diff(Time.at(0), Time.at(sec))[:diff]
  end

  def run
    program :name, $0
    program :version, '1.0.0'
    program :description, 'Circle CLI'

    command :timing do |c|
      c.syntax = "circle.rb timing username repo"
      c.description = 'Get Timing information from Circle CI'
      c.option '--branch=develop', '-b', 'Branch to check'

      c.action do |args, options|
        options.default branch: 'develop'

        username, repo = args
        branch = options.branch

        raise 'must specify username' unless username
        raise 'must specify repo' unless repo

        res = CircleCi::Project.recent_builds_branch username, repo, branch
        raise "failed" unless res.success?

        data = []

        res.body.each do |build|
          if build['outcome'] == 'success'
            data << build['build_time_millis']
          end
        end

        stats = DescriptiveStatistics::Stats.new(data)

        puts "Min: #{format_ms(stats.min)}"
        puts "Max: #{format_ms(stats.max)}"
        puts "90%: #{format_ms(stats.value_from_percentile(90))}"
        puts "Mean: #{format_ms(stats.mean)}"
        puts "Median: #{format_ms(stats.median)}"
        puts "StdDev: #{format_ms(stats.standard_deviation)}"
      end
    end

    run!
  end
end

CircleCLI.new.run

# Main {
#
#   mode :list do
#     def run
#
#       git = GitInfo.new
#       git.ensure_github!
#
#       res = CircleCi::Project.recent_builds_branch git.username, git.repo, git.current_branch
#       raise "failed" unless res.success?
#
#       puts "Branch Builds:".colorize(:yellow)
#
#       res.body.each do |build|
#         print_build(build)
#       end
#
#     end
#   end
#
#   mode :info do
#     argument 'build_number'
#
#     def run
#       git = GitInfo.new
#       git.ensure_github!
#
#       build = params['build_number'].value
#       BuildInfo.build_status git.username, git.repo, build
#     end
#   end
#
#   def run
#     help!
#   end
# }
