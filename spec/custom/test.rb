require "pry"
require "/Users/mrbrdo/ruby/ruby-ybc/lib/ruby-ybc/extension_generator"
RubyYbc::ExtensionGenerator.create_from_str(<<-EOF)
module FibonacciRecursive
  def self.fib(n)
    n < 2 ? n : fib(n-1) + fib(n-2)
  end
  
  def self.run
    t = Time.now.to_i
    puts self.fib(39)
    puts "Time: " + (Time.now.to_i - t).to_s
    #puts "Time: "
    #puts (Time.now.to_i - t).to_s
  end
end

puts FibonacciRecursive.run
EOF
