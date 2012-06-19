def rb_example name
  require_relative "../examples/#{name}"
end

def compiled_example name
  base_dir = File.expand_path("../../../", __FILE__)
  
  str = File::read("#{base_dir}/spec/examples/#{name}.rb")
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

def example_should_have_equal_output name
    rb_example name
    out_rb = capture_stdout do
      (name.camelize.constantize)::run
    end
    compiled_example name
    out_c = capture_stdout do
      ("#{name.camelize}C".constantize)::run
    end
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