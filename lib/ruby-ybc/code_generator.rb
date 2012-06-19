require_relative './preprocessor'
class CodeGenerator
  attr_reader :code
  attr_reader :iseq
  def initialize func_name, iseq, parent_iseq = nil
    iseq = iseq.to_a unless @iseq.kind_of? Array
    @iseq = iseq.dup
    @iseq = Preprocessor.new(@iseq).iseq
    @func_name = func_name.to_s
    @stack_max = @iseq[4][:stack_max]
    @local_size = @iseq[4][:local_size]
    @defined_blocks = 0
    @rsp = -1 # some space for function
    @parent_iseq = parent_iseq
    @code = ""
    prologue
    begin
      process
    rescue StandardError => e
      binding.pry
    end
  end
  
  def inc_rsp qwords = 1
    @rsp += qwords
  end
  
  def dec_rsp qwords = 1
    @rsp -= qwords
  end
  
  def prologue
    head = "VALUE #{@func_name}_impl(nabi_t self"+(2..@local_size).map{|i| ", nabi_t v#{i}"}.join+")";
    exec "#{head} __attribute__((noinline));"
    exec "#{head} {"
    exec "  RB_ENTER(#{@stack_max}, #{@local_size});"
  end
  
  def epilogue
  	exec "  RB_LEAVE(#{@rsp});"
  	exec "}"
  end
  
  def self.convert_object(obj)
    if obj.kind_of? Fixnum
      "INT2NUM(#{obj})"
    elsif obj.kind_of? Symbol
      "ID2SYM(rb_intern(\"#{obj}\"))"
    else
      raise "Don't know how to parse #{obj.class}"
    end
  end
  
  def yarv_putobject obj, do_convert = true # do_convert so I can reuse this
    @last_putobject = obj
    inc_rsp
    obj = self.class.convert_object(obj) if do_convert
    exec "  YARV_PUTOBJECT(#{obj}, #{@rsp});"
  end
  
  def yarv_opt_plus ic
    exec "  YARV_PUTOBJECT(LONG2FIX(
      FIX2LONG(sp[#{@rsp}]) +
      FIX2LONG(sp[#{@rsp-1}]), #{@rsp-1});"
    dec_rsp
  end
  
  def yarv_setlocal idx
    exec "  YARV_SETLOCAL(v#{idx}, #{@rsp});"
    dec_rsp
  end
  
  def yarv_getlocal idx
    inc_rsp
    exec "  YARV_GETLOCAL(v#{idx}, #{@rsp});"
  end
  
  def yarv_getdynamic idx, scope
    inc_rsp
    exec "  YARV_GETDYNAMIC(#{idx}, #{scope}, #{@rsp});"
  end
  
  def yarv_putself
    if @iseq[9] == :block
      yarv_getdynamic(1, 1)
    else
      inc_rsp
      exec "  YARV_PUTSELF(#{@rsp});"
    end
  end
  
  def yarv_putstring str
    inc_rsp
    exec "  YARV_PUTSTRING(\"#{str}\", #{@rsp});"
  end
  
  def yarv_putnil
    yarv_putobject "Qnil", false
  end
  
  def yarv_putiseq iseq
    @last_putiseq = iseq
  end
  
  def yarv_send op_id, n_args, blockptr, flags, ic
    if op_id == :"core#define_singleton_method"
      yarv_custom_defmethod @last_putobject, @last_putiseq
      @last_putiseq = nil
      return
    end
    raise "putiseq not used!" unless @last_putiseq.nil?
    # compiler optimizes and doesn't save local variables, so must refresh
    exec '  asm(""::'+(2..@local_size).map{|i|"\"m\"(v#{i})"}.join(",")+'); // refresh vars'
    exec "  YARV_SEND(#{@rsp}, ", false
    # block
    unless blockptr.nil?
      @defined_blocks += 1
      compile_method "#{@func_name}_block#{@defined_blocks}", blockptr
    end
    exec "#{@rsp-n_args}, \"#{op_id}\", #{n_args}" +
      (0...n_args).map{|i| ", sp[#{@rsp-i}]"}.join + ");"
    exec '  asm("":'+(2..@local_size).map{|i|"\"=m\"(v#{i})"}.join(",")+'); // refresh vars'
    dec_rsp (n_args + 1) # pop args + self from stack
    inc_rsp 1 # push result
  end
  
  def stub
    argc = @iseq[4][:arg_size]
    args = (1..argc).map{|i| ", VALUE arg#{i}"}.join
    # def met a, b, c
    # locals d, e
    # a is local6
    # b is local5
    # c is local4
    # d,e are local3 and local2
    # there doesn't seem to be any local1 (probably reserved for self)
    # func_impl(self, locals(2-x), ..., arg3, arg2, arg1)
    casted_args = ["(nabi_t)(VALUE)(0)"] * (@local_size-argc-1)
    casted_args += argc.downto(1).map{|i| "(nabi_t)(arg#{i})"}
    casted_args.unshift("") unless casted_args.empty?
    casted_args = casted_args.join(", ")
    n_args = @local_size + 1 # locals + self
<<-STUB
VALUE #{@func_name}(VALUE self#{args})
{
  return #{@func_name}_impl((nabi_t)self#{casted_args});
}
STUB
  end
  
  def yarv_leave
    if @rsp != 0
      puts "WARNING: Something weird with stack!"
    end
    epilogue
  end
  
  def yarv_pop
    dec_rsp
  end
  
# Special stuff

  def yarv_custom_defmethod name, iseq
    compile_method name, iseq
    argc = iseq[4][:arg_size]
    exec "rb_define_singleton_method(self.d, \"#{name}\", #{name}, #{argc});"
    @rsp -= 1
    # TODO supposed to return something here
  end
  
  def yarv_custom_defsmethod name, iseq
    compile_method name, iseq
    argc = iseq[4][:arg_size]
    exec "rb_define_singleton_method(self.d, \"#{name}\", #{name}, #{argc});"
  end
  
  def yarv_custom_newproc argc, blockptr
    @defined_blocks += 1
    proc_name = "#{@func_name}_block#{@defined_blocks}"
    compile_method proc_name, blockptr
    yarv_putobject("rb_new_native_proc(#{proc_name}, #{argc}, (uintptr_t) &self, #{@local_size})", false)
  end
  
  def yarv_defineclass name, iseq, todo
    compile_method name, iseq
    exec "  #{name}(rb_define_class(\"#{name}\", rb_cObject));"
    # TODO should put class on stack probably, dunno what it expects as return
  end
  
  def yarv_putspecialobject num
    puts "putspecialobject not implemented"
  end
  
# TODO methods
  def yarv_trace i
  end
  
  def yarv_invokeblock i, j
    
  end

  def yarv_getinlinecache i, j

  end
  
  def yarv_setinlinecache i

  end
  
  def yarv_getconstant i

  end
# END TODO
  
  def compile_method(name, iseq)
    exec "  // Compiled method #{name.inspect}."
    @code = CodeGenerator.new(name, iseq, @iseq).code_with_stub + "\n#{@code}"
  end
  
  def method_init_code
    if @iseq[9] == :block
      
    end
  end
  
  def process
    @iseq[13].each do |op|
      next unless op.kind_of? Array
      
      op_display = op.map{|i| i.kind_of?(Array) ? "Array" : i.inspect}.join(", ")
      op_display = "YARV " + op_display.sub(",", ":")
      op_display = op_display.sub(":", "")
      exec "  // #{op_display}"
      name = op[0]
      op = op.slice(1, op.count)
      self.send("yarv_#{name}", *op)
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
end