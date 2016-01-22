require 'spec_helper'

describe RSpec::EM::SyncSteps do
  @step_module = RSpec::EM.sync_steps do
    def multiply(x, y)
      @result = x * y
    end

    def subtract(n)
      @result -= n
    end

    def check_result(n)
      expect(@result).to eq n
      @checked = true
    end
  end

  include @step_module

  it 'passes' do
    multiply 6, 3
    subtract 7
    check_result 11
  end
end
