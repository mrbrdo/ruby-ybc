def rb_example num
  require_relative "../examples/example#{num}"
end

def compiled_example num
  base_dir = File.expand_path("../../../", __FILE__)
  
  str = File::read("#{base_dir}/spec/examples/example#{num}.rb")
  str = str.sub("\n", "C\n")
  iseq = RubyVM::InstructionSequence::compile(str)

  begin
    cg = CodeGenerator.new("toplevel_function", iseq)
  rescue StandardError => e
    puts e.message
    pp cg.iseq.to_a
    exit
  end
  system("cd \"#{base_dir}/ext/locals\" && cp template.txt locals.c")
  c_file = "#{base_dir}/ext/locals/locals.c"
  c = File::read(c_file)
  File::open(c_file, "w") {|f| f.write c.sub("#functions_section", cg.code_with_stub)}

  system("cd \"#{base_dir}\" && rake")
  raise "Compile unsuccessful!" unless $?.success?
  require "#{base_dir}/lib/locals/locals"
end

def example_should_have_equal_output num
    rb_example num
    out1 = capture_stdout do
      eval("Example#{num}")::run
    end
    compiled_example num
    out2 = capture_stdout do
      eval("Example#{num}C")::run
    end
    out1.should eq(out2)
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