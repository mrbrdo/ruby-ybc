require 'fileutils'
module RubyYbc
  class ExtensionGenerator
    def initialize(name, path)
      @name = name
      @path = path
      @my_path = File.expand_path("../", __FILE__)
      FileUtils.mkdir_p(@path)
    end
    
    def create_extension code
      file "extconf.rb", EXTCONF_TEMPLATE.gsub("#ext_name", @name)
      file "Rakefile", RAKEFILE_TEMPLATE.gsub("#ext_name", @name)
      file "#{@name}.c", File.read("#{@my_path}/files/template.txt").sub("#functions_section", code).gsub("#ext_name", @name)
      Dir.glob("#{@my_path}/files/*{.h,.c}").each do |f|
        FileUtils.cp("#{f}", "#{@path}/#{File.basename(f)}")
      end
      build
    end

    def self.create_from_str code
      require_relative './code_generator'
      name = "test"
      base_dir = File::expand_path("../../../", __FILE__)

      opts = {
        :inline_const_cache => false, # no use to us, it only speeds up interpreter
        :peephole_optimization => true,
        :tailcall_optimization => false,
        :specialized_instruction => true,
        :operands_unification => false,
        :instructions_unification => false,
        :stack_caching => false,
        :debug_level => 0}
      iseq = RubyVM::InstructionSequence::compile(code, "<compiled>", "<compiled>", 1, opts)

      begin
        cg = RubyYbc::CodeGenerator.new("toplevel_function", iseq)
      rescue StandardError => e
        puts e.message
        pp cg.iseq.to_a
        exit
      end
      
      g = RubyYbc::ExtensionGenerator.new(name, "#{base_dir}/tmp/#{name}")
      g.create_extension(cg.code_with_stub)
      
      File.open("#{base_dir}/tmp/#{name}/src.rb", "w") do |f|
        f.write(code)
      end
      
      raise "Compile unsuccessful!" unless g.build
    end
    
    def build
      FileUtils.cd(@path) do
        puts %x[rake]
      end
      $?.success?
    end
    
    def file name, txt
      File.open("#{@path}/#{name}", "w") do |f|
        f.write(txt)
      end
    end
  end
  
  EXTCONF_TEMPLATE = <<eos
require 'mkmf'
$CFLAGS = "-O4 -fno-stack-protector -fomit-frame-pointer"

create_makefile('#ext_name')
eos
  RAKEFILE_TEMPLATE = <<eos
require 'rake/clean'

NAME = '#ext_name'

file "#ext_name.bundle" =>
    Dir.glob("*{.rb,.c}") do
  Dir.chdir("./") do
    ruby "extconf.rb"
    sh "make"
  end
end

CLEAN.include('*{.o,.log,.bundle}')
CLEAN.include('Makefile')

task :default => "#ext_name.bundle"
eos
end