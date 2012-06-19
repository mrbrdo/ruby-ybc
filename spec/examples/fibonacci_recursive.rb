module FibonacciRecursive
  def self.fib(n)
    n < 2 ? n : fib(n-1) + fib(n-2)
  end
  
  def self.run
    self.fib(10)
  end
end