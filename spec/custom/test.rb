require "/Users/mrbrdo/ruby/ruby-ybc/lib/ruby-ybc/extension_generator"
RubyYbc::ExtensionGenerator.create_from_str(<<-EOF)
module ProcBasic
  def self.met proc
    proc.call
  end
  
  def self.run
    a = 5
    b = 6
    met Proc.new { puts a ; puts b }
  end
end

puts ProcBasic.run
EOF
