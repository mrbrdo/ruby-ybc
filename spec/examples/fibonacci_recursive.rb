module FibonacciRecursive
  def self.fib(n)
    n < 2 ? n : fib(n-1) + fib(n-2)
  end
  
  def self.run
    t = Time.now
    puts self.fib(19)
    #puts "Time: " + (Time.now - t).to_s
  end
end