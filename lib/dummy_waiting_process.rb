require 'thread'

class DummyWaitingProcess

  def run
    begin
      puts 'Waiting for Ctrl-C'
      sleep
    rescue Interrupt
      puts 'Got Ctrl-C, exit'
      exit
    end
  end

end
