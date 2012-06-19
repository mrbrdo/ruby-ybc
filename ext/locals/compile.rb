require_relative './code_generator'
require 'pry'

iseq = RubyVM::InstructionSequence::compile(<<-FUNC
def met proc
  proc.call
end
a = 1313
b = "Lol"
met Proc.new { puts a ; puts b }
5
FUNC
)

pp iseq.to_a
cg = CodeGenerator.new("top", iseq)
puts "****************"
puts cg.code
puts cg.stub
puts "****************"
puts "Eval:"
puts "\n=> " + iseq.eval.inspect

cg = CodeGenerator.new("toplevel_function", iseq)
system("cd " + File::expand_path("../", __FILE__) + " && cp template.txt locals.c")
c = File::read("locals.c")
File::open("locals.c", "w") {|f| f.write c.sub("#functions_section", cg.code_with_stub)}

system("cd ../.. && rake && cd ext/locals")
require_relative "./locals"