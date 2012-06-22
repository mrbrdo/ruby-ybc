require File.expand_path('../../spec_helper', __FILE__)

describe CodeGenerator do
  Dir[File::expand_path("../../examples/cl*.rb", __FILE__)].each do |file|
    it "passes example #{File.basename(file, '.rb')}" do
      example_should_have_equal_output File.basename(file, ".rb")
    end
  end
end