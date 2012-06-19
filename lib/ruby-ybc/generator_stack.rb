module RubyYbc
  class GeneratorStack
    class LocalVar ; end
    class SelfVar ; end
    class IseqVar ; end
    class SpecialObjectVar ; end
    class RubyObjectVar ; end
    attr_reader :ptr
    def initialize(max)
      @max = max
      @ptr = -1
      @pending = []
    end
  
    def push obj, *args, &block
      r = if block_given?
        block
      else
        obj
      end
      @pending.push([obj, r])
    end
  
    def pop
      if @pending.empty?
        dec
      else
        @pending.pop.tap do |i|
          if i[1].respond_to?(:call)
            i[1] = i[1].call(self)
          end
        end
      end
    end
    
    def pop_lucky
      pop[1]
    end
    
    def pendingc
      @pending.count
    end
    
    def inc how_much = 1
      @ptr += how_much
    end
    
    def dec how_much = 1
      @ptr -= how_much
    end
    
    def commit
      r = []
      @ptr += @pending.count
      ptr = @ptr
      while !@pending.empty?
        obj = pop
        r.push "  YARV_PUTOBJECT(#{obj[1]}, #{ptr});"
        ptr -= 1
      end
      r.reverse.join("\n")
    end
    
    def <(val)
      @ptr < val
    end
    
    def >(val)
      @ptr > val
    end
    
    def -(val)
      @ptr - val
    end
    
    def +(val)
      @ptr + val
    end
    
    def to_s
      @ptr.to_s
    end
  end
end