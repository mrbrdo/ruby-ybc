module Example1
  def self.met proc
    proc.call
  end
  
  def self.run
    a = 5
    b = 6
    met Proc.new { puts a ; puts b }
  end
end