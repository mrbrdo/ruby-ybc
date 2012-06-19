require 'pry'

funcs = File::read(File.expand_path("../../../ruby/insns.def", __FILE__))

name = ARGV[0]

r = Regexp.new(<<eos.strip)
DEFINE_INSN\\s+#{name}
eos

# }.*(\\/\\*\\*[.\\n]+DEFINE_INSN[$\\s]+#{name}.*)\\/\\*\\*

at = funcs =~ r

start = funcs.rindex("/**", at)
strend = funcs.index("}", at) + 1

func = funcs[start, strend-start]
puts func

declstart = func.index("DEFINE_INSN")
declend = func.index("}") + 1

header = func[declstart, declend-declstart]
cheader = "/*"+header+"*/"
name = "yarv_#{name}".upcase
func = func.gsub(header, cheader + "\n#define #{name}() \\\n")

File::open(File.expand_path("../ext/locals/instr.h", __FILE__), "a") do |f|
  f.puts "\n#{func}"
end