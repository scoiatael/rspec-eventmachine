module RSpec::EM
  class SyncSteps < AsyncSteps
    PREFIX = 'with_cb_'
    PREFIX_REGEXP = Regexp.new('^' + PREFIX)

    def method_added(method_name)
      with_cb_method_name = with_cb_method_name(method_name)

      return if ignored_method(method_name, PREFIX_REGEXP, with_cb_method_name)

      module_eval do
        alias_method with_cb_method_name.to_sym, method_name.to_sym

        define_method(method_name) do |*args, &cb|
          send(with_cb_method_name, *args)
          cb.call
        end
      end

      super(method_name)
    end

    def ignored_method(method_name, regex = nil, alternative_name = nil)
      return true if super(method_name)

      super
    end

    def with_cb_method_name(method_name)
      "#{PREFIX}#{method_name}"
    end
  end
end
