module ClassBasic
  class MyClass
    def initialize a
      
    end
    
    def test
      puts "Class instance method working!"
    end
  end
  
  def self.run
    m = MyClass.new(0x1337)
    m.test
  end
end