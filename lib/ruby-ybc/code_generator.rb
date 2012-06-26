require_relative './preprocessor'
require_relative './generator_stack'
require_relative './code_generator/method_generator'
module RubyYbc
  class CodeGenerator
    attr_reader :code
    attr_reader :iseq
    attr_reader :rsp
    def initialize func_name, iseq, parent_iseq = nil
      iseq = iseq.to_a unless @iseq.kind_of? Array
      @iseq = iseq.dup
      @iseq = Preprocessor.new(@iseq).iseq
      @func_name = func_name.to_s
      @stack_max = @iseq[4][:stack_max]
      @local_size = @iseq[4][:local_size]
      @defined_blocks = 0
      @rsp = GeneratorStack.new(self, @stack_max)
      @parent_iseq = parent_iseq
      @cbase = {:methods => {func_name.to_s => "((#{func_name}_fptr)(method_dispatch_ptr(CLASS_OF(self.d), \"#{func_name}\")))("}}
      @code = ""
      @indent = 0
      prologue
      begin
        process
      rescue StandardError => e
        puts e.message
        puts e.backtrace
        binding.pry
      end
    end
  
    def yarv_putobject obj
      if obj.kind_of? Fixnum
        rsp.push("LL2NUM(#{obj})", obj)
      elsif obj.kind_of? Symbol
        rsp.push("ID2SYM(rb_intern(\"#{obj}\"))", obj)
      else
        raise "Don't know how to parse #{obj.class}"
      end
    end
    
    def yarv_branchunless lab
      rsp.commit
      exec tpl("branchunless", cond: "sp[--rsp]", lab: label_full_name(lab))
    end
    
    def yarv_jump lab
      rsp.commit
      exec tpl("jump", lab: label_full_name(lab))
    end
  
    def yarv_setlocal idx
      exec tpl("setlocal", local: "v#{idx}", stack: rsp.pop_lucky)
      rsp.commit
    end
    
    def yarv_getlocal idx
      rsp.push("v#{idx}.d", GeneratorStack::LocalVar)
    end
  
    def yarv_getdynamic idx, scope
      rsp.commit
      exec tpl("getdynamic", idx: idx, scope: scope, stack: "sp[rsp++]")
    end
  
    def yarv_putself
      if @iseq[9] == :block
        rsp.commit
        yarv_getdynamic(1, 1)
      else
        rsp.push("self.d", GeneratorStack::SelfVar)
      end
    end
  
    def yarv_putstring str
      rsp.push("rb_str_new2(\"#{str}\")")
    end
  
    def yarv_putnil
      rsp.push("Qnil", nil)
    end
  
    def yarv_putiseq iseq
      rsp.push(iseq, GeneratorStack::IseqVar)
    end

    include RubyYbc::MethodGenerator
  
    def yarv_leave
      epilogue
    end
  
    def yarv_pop
      rsp.pop
      rsp.commit # TODO necessary?
    end
  
  # Special stuff
  
    def yarv_defineclass name, iseq, define_type
      raise ArgumentError if rsp.pending.count < 2
      
      zuper = rsp.pop
      zuper[0] = "rb_cObject" if zuper[1] == nil
      cbase = rsp.pop
      
      compile_method name, iseq
      
      val = tpl("defineclass(#{define_type})", name: name, zuper: zuper[0], cbase: cbase[0])
      exec tpl("defineclass_full", klass: val.first, name: name, stack: rsp.to_s)
      rsp.commit
    end
  
    def yarv_putspecialobject num
      rsp.push(num, GeneratorStack::SpecialObjectVar)
      puts "putspecialobject not implemented"
    end
  
  # YARV OPT
    def yarv_opt_lt ic
      rsp.push tpl("opt_lt", b: rsp.pop_lucky, a: rsp.pop_lucky)
      rsp.commit
    end
    
    def yarv_opt_minus ic
      rsp.push tpl("opt_minus", right: rsp.pop_lucky, left: rsp.pop_lucky)
      rsp.commit
    end
    
    def yarv_opt_plus ic
      rsp.push tpl("opt_plus", right: rsp.pop_lucky, left: rsp.pop_lucky)
      rsp.commit
    end
    
  # TODO methods
    def yarv_trace i
      
    end
  
    def yarv_invokeblock i, j
    
    end

    def yarv_getinlinecache i, j
      raise "Disable inline cache."
    end
    def yarv_setinlinecache i
      raise "Disable inline cache."
    end
  
    def yarv_getconstant name
      recvr = rsp.pop
      # todo handle if recvr is nil, look at vm_get_ev_const
      if recvr[1].nil?
        recvr = "rb_cObject" 
      else
        recvr = recvr[0]
      end
      if name.kind_of? Symbol
        rsp.push("rb_const_get_from(#{recvr}, rb_intern(\"#{name}\"))",
          GeneratorStack::RubyObjectVar)
        rsp.commit
      else
        raise "Don't know constant type #{name.class}"
      end
    end
  # END TODO
    
    def label_full_name(lab)
      "#{@func_name}_#{lab}"
    end
    
    def label_now(lab)
      exec "#{label_full_name(lab)}:"
    end
  
    def process
      @iseq[13].each do |op|
        if op.kind_of? Array
          # display comment
          op_display = op.map{|i| i.kind_of?(Array) ? "Array" : i.inspect}.join(", ")
          op_display = "YARV " + op_display.sub(",", ":")
          op_display = op_display.sub(":", "")
          exec "// #{op_display}"
          # exec instruction
          name = op[0]
          op = op.slice(1, op.count)
          self.send("yarv_#{name}", *op)
        elsif op.kind_of? Symbol
          label_now(op)
        end
      end
      code_with_stub
    end
  
    def code_with_stub
      code + "\n" + stub
    end
  
    def exec(input,newline=true)
      stra = Array(input)
      stra.each do |str|
        @code += (" " * @indent) + str
        @code += "\n" if newline
      end
    end
    
    def tpl(name, vars)
      @tpl_file ||= File.read(File.expand_path("../instr.c", __FILE__))
      @tpl_file =~ Regexp.new("^- #{Regexp.escape(name)}:\s*([^\\-]*)", Regexp::MULTILINE)
      raise "Can't find template for instruction #{name}." if $1.nil?
      result = $1.strip
      vars.each_pair do |k,v|
        result.gsub!("::#{k}", v.to_s)
      end
      result.split("\n")
    end
  end
end