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
      prologue
      begin
        process
      rescue StandardError => e
        puts e.message
        puts e.backtrace
        binding.pry
      end
    end
    
    def prologue
      head = "VALUE #{@func_name}_impl(nabi_t self"+(2..@local_size).map{|i| ", nabi_t v#{i}"}.join+")"
      exec "typedef VALUE (*#{@func_name}_fptr)(nabi_t"+(2..@local_size).map{|i| ", nabi_t"}.join+");"
      exec "#{head} __attribute__((noinline));"
      exec "#{head} {"
      exec "  RB_ENTER(#{@stack_max}, #{@local_size});"
    end
  
    def epilogue
      exec rsp.commit
    	exec "  RB_LEAVE(#{@rsp-1});"
    	exec "}"
    end
  
    def yarv_putobject obj
      if obj.kind_of? Fixnum
        rsp.push(obj) do
          "LL2NUM(#{obj})"
        end
      elsif obj.kind_of? Symbol
        rsp.push(obj) do
          "ID2SYM(rb_intern(\"#{obj}\"))"
        end
      else
        raise "Don't know how to parse #{obj.class}"
      end
    end
    
    def yarv_branchunless lab
      exec rsp.commit
      exec "  if (!RTEST(#{@rsp-1})) goto #{label_full_name(lab)};"
    end
    
    def yarv_jump lab
      exec rsp.commit
      exec "  goto #{label_full_name(lab)};"
    end
  
    def yarv_setlocal idx
      exec rsp.commit
      exec "  YARV_SETLOCAL(v#{idx}, #{@rsp-1});"
      rsp.dec
    end
    
    def yarv_getlocal idx
      rsp.push(GeneratorStack::LocalVar, idx) do
        "v#{idx}.d"
      end
    end
  
    def yarv_getdynamic idx, scope
      exec rsp.commit
      rsp.inc
      exec "  YARV_GETDYNAMIC(#{idx}, #{scope}, #{@rsp-1});"
    end
  
    def yarv_putself
      if @iseq[9] == :block
        exec rsp.commit
        yarv_getdynamic(1, 1)
      else
        rsp.push(GeneratorStack::SelfVar) do
          "self.d"
        end
      end
    end
  
    def yarv_putstring str
      rsp.push(str) do
        "rb_str_new2(\"#{str}\")"
      end
    end
  
    def yarv_putnil
      rsp.push(nil) do
        "Qnil"
      end
    end
  
    def yarv_putiseq iseq
      rsp.push(GeneratorStack::IseqVar) do
        iseq
      end
    end

    include RubyYbc::MethodGenerator
  
    def yarv_leave
      epilogue
    end
  
    def yarv_pop
      rsp.pop
    end
  
  # Special stuff
  
    def yarv_defineclass name, iseq, define_type
      raise ArgumentError if rsp.pendingc < 2
      
      zuper = rsp.pop
      zuper[1] = "rb_cObject" if zuper[0] == nil
      cbase = rsp.pop
      
      compile_method name, iseq
      
      val = tpl("defineclass(#{define_type})", name: name, zuper: zuper[1], cbase: cbase[1])
      val = "VALUE tmp = #{val};"

      exec "{"
      exec val
      exec "append_method_to_dispatch_table(tmp, \"#{name}\", (uintptr_t)#{name}_impl);"
      exec "#{name}(tmp);"
      exec "YARV_PUTOBJECT(tmp, sp[rsp++]);"
      exec "}"
      #val = "#{name}(#{val})"
      #rsp.push(GeneratorStack::RubyObjectVar) do
      #  val
      #end
      exec rsp.commit # have to commit because we are calling defineclass
    end
  
    def yarv_putspecialobject num
      rsp.push(GeneratorStack::SpecialObjectVar) do
        num
      end
      puts "putspecialobject not implemented"
    end
  
  # YARV OPT
    def yarv_opt_lt ic
      exec rsp.commit
      rsp.dec 2
      rsp.push nil do
        "((SIGNED_VALUE)#{@rsp} < (SIGNED_VALUE)#{@rsp+1}) ? Qtrue : Qfalse"
      end
      exec rsp.commit
    end
    
    def yarv_opt_minus ic
      exec rsp.commit
      rsp.dec 2
      rsp.push nil do
        "LONG2FIX(FIX2LONG(#{@rsp}) - FIX2LONG(#{@rsp+1}))"
      end
      exec rsp.commit
    end
    
    def yarv_opt_plus ic
      exec rsp.commit
      rsp.dec 2
      rsp.push nil do
        "LONG2FIX(FIX2LONG(#{@rsp}) + FIX2LONG(#{@rsp+1}))"
      end
      exec rsp.commit
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
      if recvr[0].nil?
        recvr = "rb_cObject" 
      else
        recvr = recvr[1]
      end
      if name.kind_of? Symbol
        rsp.push(GeneratorStack::RubyObjectVar) do
          "rb_const_get_from(#{recvr}, rb_intern(\"#{name}\"))"
        end
      else
        raise "Don't know constant type #{name.class}"
      end
    end
  # END TODO
    
    def label_full_name(lab)
      "#{@func_name}_#{lab}"
    end
    
    def label_now(lab)
      exec "  #{label_full_name(lab)}:"
    end
  
    def process
      @iseq[13].each do |op|
        
        if op.kind_of? Array
          op_display = op.map{|i| i.kind_of?(Array) ? "Array" : i.inspect}.join(", ")
          op_display = "YARV " + op_display.sub(",", ":")
          op_display = op_display.sub(":", "")
          exec "  // #{op_display}"
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
  
    def exec(str,newline=true)
      @code += str
      @code += "\n" if newline
    end
    
    def tpl(name, vars)
      @tpl_file ||= File.read(File.expand_path("../instr.c", __FILE__))
      @tpl_file =~ Regexp.new("^- #{Regexp.escape(name)}:\s*([^\\-]*)", Regexp::MULTILINE)
      raise "Can't find template for instruction #{name}." if $1.nil?
      result = $1.strip
      vars.each_pair do |k,v|
        result.gsub!("::#{k}", v.to_s)
      end
      result
    end
  end
end