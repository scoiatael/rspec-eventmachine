module RSpec::EM
  class AsyncSteps < Module
    
    def included(klass)
      klass.__send__(:include, Scheduler)
    end
    
    def method_added(method_name)
      async_method_name = async_method_name(method_name)

      return if ignored_method(method_name)

      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        alias :#{async_method_name} :#{method_name}

        def #{method_name}(*args)
          __enqueue__([#{async_method_name.inspect}] + args)
        end
      RUBY
    end

    def async_method_name(method_name)
      "async_#{method_name}"
    end

    def ignored_method(method_name, regex = nil, alternative_name = nil)
      regex ||= /^async_/
      alternative_name ||= async_method_name(method_name)

      instance_methods(false)
        .map(&:to_s)
        .include?(alternative_name) ||
        method_name.to_s =~ regex
    end
    
    module Scheduler
      def __enqueue__(args)
        @__step_queue__ ||= []
        @__step_queue__ << args
        return if @__running_steps__
        @__running_steps__ = true
        EventMachine.next_tick { __run_next_step__ }
      end
      
      def __run_next_step__
        step = @__step_queue__.shift
        return EventMachine.stop unless step
        
        method_name, args = step.shift, step
        begin
          method(method_name).call(*args) { __run_next_step__ }
        rescue Object
          __end_steps__
          raise
        end
      end
      
      def __end_steps__
        @__step_queue__ = []
        __run_next_step__
      end
      
      def verify_mocks_for_rspec
        EventMachine.reactor_running? ? false : super
      end
      
      def teardown_mocks_for_rspec
        EventMachine.reactor_running? ? false : super
      end
    end
    
  end
end

class RSpec::Core::Example
  hook_method = %w[with_around_hooks with_around_each_hooks with_around_example_hooks].find { |m| instance_method(m) rescue nil }

  class_eval <<-RUBY, __FILE__, __LINE__ + 1
    alias :synchronous_run :#{hook_method}
    
    def #{hook_method}(*args, &block)
      if @example_group_instance.is_a?(RSpec::EM::AsyncSteps::Scheduler)
        EventMachine.run { synchronous_run(*args, &block) }
        @example_group_instance.verify_mocks_for_rspec
        @example_group_instance.teardown_mocks_for_rspec
      else
        synchronous_run(*args, &block)
      end
    end
  RUBY
end
