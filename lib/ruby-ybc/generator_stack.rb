module RubyYbc
  class GeneratorStack
    class LocalVar ; end
    class SelfVar ; end
    class IseqVar ; end
    class SpecialObjectVar ; end
    class RubyObjectVar ; end
    attr_reader :ptr
    attr_reader :pending
    def initialize(generator, max)
      @max = max
      @pending = []
      @generator = generator
      @pop_counter = 0
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
        @pop_counter += 1
        [nil, "sp[rsp-(#{@pop_counter})]"]
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
      @generator.exec "  rsp+=#{how_much};"
    end
    
    def dec how_much = 1
      @pop_counter -= how_much
      @generator.exec "  rsp-=#{how_much};"
    end
    
    def commit
      @pop_counter = 0
      r = []
      while !@pending.empty?
        obj = pop
        r.push "  YARV_PUTOBJECT(#{obj[1]}, sp[rsp++]);"
      end
      @generator.exec r.reverse.join("\n")
      ""
    end
    
    def -(val)
      "sp[rsp-#{val}]"
    end
    
    def +(val)
      "sp[rsp+#{val}]"
    end
    
    def to_s
      "sp[rsp]"
    end
  end
end