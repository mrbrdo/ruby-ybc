module RubyYbc
  class GeneratorStack
    class LocalVar ; end
    class SelfVar ; end
    class IseqVar ; end
    class SpecialObjectVar ; end
    class RubyObjectVar ; end
    class CommandInC; end
    attr_reader :ptr
    attr_reader :pending
    def initialize(generator, max)
      @max = max
      @pending = []
      @generator = generator
      @pop_idx = 0
    end
  
    def push obj_str, hint = GeneratorStack::CommandInC
      @pending.push([obj_str, hint])
    end

    def pop
      if @pending.empty?
        @pop_idx += 1
        [self-0, GeneratorStack::CommandInC]
      else
        @pending.pop
      end
    end
    
    def pop_lucky
      pop[0]
    end
    
    def inc how_much = 1
      commit
      @generator.exec "rsp+=#{how_much};"
    end
    
    def dec how_much = 1
      how_much.times { pop }
      commit
      #@generator.exec "  rsp-=#{how_much};"
    end
    
    def commit
      pop_idx = @pop_idx
      @pop_idx = 0
      r = []
      while !@pending.empty?
        obj = pop
        obj_value = obj[0]
        if obj_value.kind_of? Array
          raise "Don't know how to push multiline into stack." if obj_value.count > 1
          obj_value = obj_value.first
        end
        r.push "YARV_PUTOBJECT(#{obj_value}, #{self-(pop_idx-@pending.count)});"
      end
      @generator.exec r.reverse unless r.empty?
      rsp_change = pop_idx - r.count
      if rsp_change > 0
        @generator.exec "rsp-=#{rsp_change};"
      elsif rsp_change < 0
        @generator.exec "rsp+=#{rsp_change.abs};"
      end
      self
    end
    
    def -(val)
      idx = val+@pop_idx
      if idx > 0
        "sp[rsp-#{idx}]"
      elsif idx < 0
        "sp[rsp+#{idx.abs}]"
      else # == 0
        "sp[rsp]"
      end
    end
    
    def +(val)
      self-(0-val)
    end
    
    def to_s
      self-0
    end
  end
end