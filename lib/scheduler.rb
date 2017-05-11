require 'rufus-scheduler'
require 'rake'

class Scheduler
  extend Forwardable

  RETRY_COUNT = 2

  def_delegators :@scheduler, :shutdown

  def initialize
    @scheduler = Rufus::Scheduler.new

    def @scheduler.on_error(job, error)
      $logger.error "Job [#{job.id}] failed with error [#{error}]. Going to perform #{RETRY_COUNT} retries."

      retry_count = 0
      begin
        job.call
      rescue
        retry_count += 1
        $logger.warn "Performed #{retry_count} retries out of #{RETRY_COUNT} for job [#{job.id}]"
        retry if retry_count < RETRY_COUNT
      end
    end
  end

  def start
    CONFIG.startup.each { |command| rake(command, false) }

    CONFIG.scheduler.map(&:last).each do |task|
      @scheduler.interval(task.interval, first_in: task.first_in) do |job|
        command = task.rake_command
        puts "Launching rake task [#{command}]. Job id [#{job.id}]"
        puts %x[rake #{command}]
        rake_return_code = $?.exitstatus
        fail("Rake returned non zero status #{rake_return_code}") if rake_return_code != 0
      end
    end
  end

  private

  def rake(command, fail_on_error = true)
    puts "rake #{command}"
    puts %x[rake #{command}]
    rake_return_code = $?.exitstatus
    if fail_on_error && rake_return_code != 0
      fail("Rake returned non zero status #{rake_return_code}")
    end
  end
end
