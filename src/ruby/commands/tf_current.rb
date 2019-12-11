module Commands
  module TfCurrent
    PLAN_FILENAME = "foo.tfplan"

    class << self
      def run(args)
        ENV['TF_IN_AUTOMATION'] = "1"
        system("terraform init")
        if $?.success?
          system("terraform plan -out #{PLAN_FILENAME} -detailed-exitcode -compact-warnings -input=false")
          if $?.exitstatus == 0
            puts "no changes, exiting"
            return
          elsif $?.exitstatus == 1
            puts "something went wrong"
          elsif $?.exitstatus == 2
            system("terraform show -json #{PLAN_FILENAME} | plan-summary")
          else
            puts "unknown exit code: #{$?.exitstatus}"
          end
          system ENV["SHELL"]
        end
      rescue Exception => e
        p e
        sleep 5
        throw e
      end
    end
  end
end
