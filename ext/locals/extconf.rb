# file: extconf.rb  
require 'mkmf'
$CFLAGS = "-O4 -fno-stack-protector -fomit-frame-pointer"

create_makefile('locals')