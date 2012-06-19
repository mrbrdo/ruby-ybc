require 'rake/testtask'
require 'rake/clean'

NAME = 'locals'

# rule to build the extension: this says
# that the extension should be rebuilt
# after any change to the files in ext
file "lib/#{NAME}/#{NAME}.bundle" =>
    Dir.glob("ext/#{NAME}/*{.rb,.c}") do
  Dir.chdir("ext/#{NAME}") do
    # this does essentially the same thing
    # as what RubyGems does
    ruby "extconf.rb"
    sh "make"
  end
  cp "ext/#{NAME}/#{NAME}.bundle", "lib/#{NAME}"
end

# make the :test task depend on the shared
# object, so it will be built automatically
# before running the tests
task :test => "lib/#{NAME}/#{NAME}.bundle"

# use 'rake clean' and 'rake clobber' to
# easily delete generated files
CLEAN.include('ext/**/*{.o,.log,.bundle}')
CLEAN.include('ext/**/Makefile')
#todo remove this
CLEAN.include('lib/**/*.bundle')
CLOBBER.include('lib/**/*.bundle')

# the same as before
task :test do
end

desc "Run tests"
task :default => :test