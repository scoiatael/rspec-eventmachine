require 'eventmachine'
require 'rspec/mocks'
require 'set'

module RSpec
  module EventMachine
    root = File.expand_path('../eventmachine', __FILE__)

    autoload :AsyncSteps, root + '/async_steps'
    autoload :SyncSteps, root + '/sync_steps'
    autoload :FakeClock,  root + '/fake_clock'
    
    def self.async_steps(&block)
      AsyncSteps.new(&block)
    end

    def self.sync_steps(&block)
      SyncSteps.new(&block)
    end
  end

  EM = EventMachine
end

