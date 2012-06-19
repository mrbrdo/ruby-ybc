def rb_example name
  require_relative "../examples/#{name}"
end

def compiled_example name
  base_dir = File::expand_path("../../../", __FILE__)
  
  str = File::read("#{base_dir}/spec/examples/#{name}.rb")
  str = str.sub("\n", "C\n")
  opts = {
    :inline_const_cache => false, # no use to us, it only speeds up interpreter
    :peephole_optimization => false, :tailcall_optimization => false, :specialized_instruction => false, :operands_unification => false, :instructions_unification => false, :stack_caching => false, :debug_level => 0}
  iseq = RubyVM::InstructionSequence::compile(str, "#{name}.c", "<compiled>", 1, opts)

  begin
    cg = CodeGenerator.new("toplevel_function", iseq)
  rescue StandardError => e
    puts e.message
    pp cg.iseq.to_a
    exit
  end
  
  g = RubyYbc::ExtensionGenerator.new(name, "#{base_dir}/tmp/#{name}")
  g.create_extension(cg.code_with_stub)
  
  raise "Compile unsuccessful!" unless g.build
end

def run_compiled_example_in_new_process name
  test_dir = File.expand_path("../../../tmp", __FILE__)
  File.open("#{test_dir}/test#{name}.rb", "w") do |f|
    f.write <<-TEST
    require_relative './#{name}/#{name}'
    #{name.camelize}C::run
TEST
  end
  %x[ruby "#{test_dir}/test#{name}.rb"]
end

def example_should_have_equal_output name
    compiled_example name
    rb_example name
    out_rb = capture_stdout do
      (name.camelize.constantize)::run
    end
    out_c = run_compiled_example_in_new_process name
    out_c.should eq(out_rb)
end

require 'stringio'
module Kernel
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out.string
  ensure
    $stdout = STDOUT
  end
end