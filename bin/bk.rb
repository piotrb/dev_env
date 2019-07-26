#!env ruby
require "aws"
require "yaml"

gem "eventmachine"
gem "promise.rb"
# gem 'pry'

require "active_support/all"
require "eventmachine"
require "promise"
# require 'pry'

Thread.abort_on_exception = true

class MyPromise < Promise
  def defer
    EM.next_tick { yield }
  end
end

class App
  TIMINGS_BUCKET_NAME = "ph-buildkite-timings"
  REGION = "us-west-2"

  def self.run
    new.run
  end

  def initialize
    @cache = ActiveSupport::Cache.lookup_store(:file_store, File.expand_path("~/Work/tmp/cache"))
  end

  attr_reader :cache, :s3

  def run
    init_aws

    MyPromise.all(process_all_candidates).then(->(_) {
      EM.stop
    }, ->(*reasons) {
      puts "something went wrong: #{reasons.inspect}"
      exit 1
    })
  end

  private

  def process_all_candidates
    bucket = s3.buckets[TIMINGS_BUCKET_NAME]
    branch = current_branch

    slug = ENV.fetch("SLUG")
    build = ENV.fetch("BUILD")

    candidate_promises = []

    candidate_names = get_candidate_names(bucket, slug)

    candidate_names.map { |name|
      prefix = "#{slug}/#{name}/#{branch}/#{build}/failures"

      tree = bucket.as_tree(prefix: prefix)

      promises = []

      tree.children.each do |child|
        promise = MyPromise.new
        Thread.new do
          begin
            files = cache.fetch("buildkite:build:#{child.key}") do
              bucket.objects[child.key].read
            end
            Thread.exclusive do
              promise.fulfill(files)
            end
          rescue Exception => e
            Thread.exclusive do
              promise.reject(e)
            end
          end
        end
        promises << promise
      end

      MyPromise.all(promises).then(->(values) {
        puts "\n#{name}: "

        all_files = []

        values.each do |files|
          all_files += files.strip.split(" ")
        end

        all_files = all_files.map { |file|
          file.gsub(/^\.\//, "").gsub(/(:|\[).*$/, "")
        }.sort

        all_files = all_files.group_by { |x| x }

        all_files.each do |file, instances|
          puts "- #{file} (#{instances.count})"
        end
      }, ->(*reasons) {
        puts "something went wrong: #{reasons.inspect}"
      })
    }
  end

  def current_branch
    `git rev-parse --abbrev-ref HEAD`.strip
  end

  def init_aws
    config = YAML.load_file(File.expand_path("~/.aws/ph-test/aws.yml"))

    AWS.config(config.merge(region: REGION))

    @s3 = AWS::S3.new
  end

  def get_candidate_names(bucket, slug)
    prefix = "#{slug}/"
    tree = bucket.as_tree(prefix: prefix)
    result = []
    tree.children.each do |child|
      result << File.basename(child.prefix)
    end
    result
  end
end

EM.run do
  App.run
end
