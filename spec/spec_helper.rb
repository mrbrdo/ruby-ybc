require 'rubygems'
require 'spork'
require 'active_support/core_ext'
require 'pry'
require_relative '../lib/ruby-ybc/code_generator'
require_relative '../lib/ruby-ybc/extension_generator'
include RubyYbc

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

  RSpec.configure do |config|
    config.mock_with :rspec

    # Exclude broken tests
    config.filter_run_excluding :broken => true
    config.filter_run :focus => true
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end