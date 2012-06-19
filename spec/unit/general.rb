require File.expand_path('../../spec_helper', __FILE__)

describe CodeGenerator do
  it "passes examples" do
    Dir[File::expand_path("../../examples/*.rb", __FILE__)].each do |file|
      example_should_have_equal_output File::basename(file, ".rb")
      break
    end
  end
end