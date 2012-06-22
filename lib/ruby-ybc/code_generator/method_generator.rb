$method_cache_idx = 0 # TODO
module RubyYbc::MethodGenerator
  def self.included(base)
    base.class_variable_set("@@func_handlers", Hash.new)
    base.send(:extend, ClassMethods)

    base.func_handler :"core#define_method" do
      iseq = rsp.pop_lucky
      name = rsp.pop[0]
      recvr = rsp.pop_lucky
      dunno = rsp.pop_lucky
      exec rsp.commit

      @cbase[:methods][name.to_s] = true
      compile_method name, iseq
      argc = iseq[4][:arg_size]
      # !!!  rb_define_method(rb_funcall(self.d, rb_intern("class"), 0), "met", met, 1);
      #TODO!!! (reciever!)
      exec "  RYBC_DEFINE_METHOD(self.d, #{name}, #{name}_impl, #{argc});"

      # core#define_method always returns nil
      rsp.push(nil) { "Qnil" }
    end

    base.func_handler :"core#define_singleton_method" do
      iseq = rsp.pop_lucky
      name = rsp.pop[0]
      recvr = rsp.pop_lucky
      dunno = rsp.pop_lucky
      exec rsp.commit

      @cbase[:methods][name.to_s] = true
      compile_method name, iseq
      argc = iseq[4][:arg_size]
      # !!!  rb_define_method(rb_funcall(self.d, rb_intern("class"), 0), "met", met, 1);
      #TODO!!! (reciever!)
      exec "  RYBC_DEFINE_SINGLETON_METHOD(self.d, #{name}, #{name}_impl, #{argc});"

      # core#define_singleton_method always returns nil
      rsp.push(nil) { "Qnil" }
    end
  end

  module ClassMethods
    def func_handler name, &block
      self.class_variable_get("@@func_handlers")[name] = block
    end
  end

  def yarv_custom_newproc argc, blockptr
    @defined_blocks += 1
    proc_name = "#{@func_name}_block#{@defined_blocks}"
    exec rsp.commit
    compile_method proc_name, blockptr
    exec "  {"
    exec "    VALUE tmp = rb_new_native_proc(#{proc_name}, #{argc}, (uintptr_t) &self, #{@local_size});"
    exec "    append_method_to_dispatch_table(tmp, \"#{proc_name}\", (uintptr_t)#{proc_name}_impl);"
    exec "    YARV_PUTOBJECT(tmp, sp[rsp++]);"
    exec "  }"
    #rsp.push(GeneratorStack::RubyObjectVar) do
    #  "rb_new_native_proc(#{proc_name}, #{argc}, (uintptr_t) &self, #{@local_size})"
    #end
  end

  def get_func_call(klass, name) # CLASS_OF(self.d)
    $method_cache_idx += 1
    "((#{name}_fptr)(method_dispatch_ptr(#{klass}, \"#{name}\", #{$method_cache_idx})))("
  end

  def have_func_handler? name
    self.class.class_variable_get("@@func_handlers").has_key?(name)
  end

  def call_func_handler name
    self.instance_eval(&(self.class.class_variable_get("@@func_handlers")[name]))
  end

  def yarv_send op_id, n_args, blockptr, flags, ic
    if have_func_handler?(op_id)
      return call_func_handler(op_id)
    end
    raise "putiseq not used!" unless @last_putiseq.nil? # todo
    exec rsp.commit
    
    if @cbase[:methods].has_key?(op_id.to_s)
      exec "  YARV_PUTOBJECT(" + get_func_call('self.d', op_id) + "(nabi_t)self.d"
      exec (0...n_args).map{|i| ", (nabi_t)#{@rsp-(i+1)}"}.join + "), #{@rsp-(n_args+1)});"
    else
      # compiler optimizes and doesn't save local variables, so must refresh
      exec '  asm(""::'+(2..@local_size).map{|i|"\"m\"(v#{i})"}.join(",")+'); // refresh vars'
      exec "  YARV_SEND(#{@rsp-1}, ", false
      # block
      unless blockptr.nil?
        @defined_blocks += 1
        compile_method "#{@func_name}_block#{@defined_blocks}", blockptr
      end
      exec "#{@rsp-(n_args+1)}, \"#{op_id}\", #{n_args}"
      exec (0...n_args).map{|i| ", #{@rsp-(i+1)}"}.join + ");"
      exec '  asm("":'+(2..@local_size).map{|i|"\"=m\"(v#{i})"}.join(",")+'); // refresh vars'
    end
    rsp.dec (n_args + 1) - 1 # pop args + self from stack and push result
  end

  # Generates a stub for a method. For example:
  # def met a, b, c
  #   d = e = 1234
  # a is local6
  # b is local5
  # c is local4
  # d,e are local3 and local2
  # there doesn't seem to be any local1 (probably reserved for self)
  # func_impl(self, locals(2,3,4...), args(...,3,2,1))
  def stub
    argc = @iseq[4][:arg_size]
    args = (1..argc).map{|i| ", VALUE arg#{i}"}.join
    func_call_str = get_func_call('self.d', @func_name)
    casted_args = ["(nabi_t)(VALUE)(0)"] * (@local_size-argc-1)
    casted_args += argc.downto(1).map{|i| "(nabi_t)(arg#{i})"}
    casted_args.unshift("") unless casted_args.empty?
    casted_args = casted_args.join(", ")
    n_args = @local_size + 1 # locals + self
<<-STUB
VALUE #{@func_name}(VALUE selfv#{args})
{
  nabi_t self = (nabi_t) selfv;
  return #{func_call_str}(nabi_t)self#{casted_args});
}
STUB
  end

  def compile_method(name, iseq)
    exec "  // Compiled method #{name.inspect}."
    @code = RubyYbc::CodeGenerator.new(name, iseq, @iseq).code_with_stub + "\n#{@code}"
  end
end