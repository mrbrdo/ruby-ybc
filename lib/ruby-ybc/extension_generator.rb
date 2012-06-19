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