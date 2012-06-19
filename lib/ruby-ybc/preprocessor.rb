class Preprocessor
  attr_accessor :iseq
  def initialize iseq
    @iseq = iseq
    @body = @iseq[13].reject {|i| i.kind_of? Fixnum }
    process
  end
  
  def match_instruction instr, mask
    return false if mask.kind_of?(Array) && !(instr.kind_of?(Array))
    return true if mask == Symbol && instr.kind_of?(Symbol)
    match_count = mask.count - 1
    if mask.last == "+"
      return false if instr.count < mask.count
    elsif mask.last == "*"
      return false if instr.count < mask.count - 1
    else
      return false if instr.count != mask.count
      match_count += 1
    end
    
    instr.slice(0, match_count) == mask.slice(0, match_count)
  end
  
  def replace_sequence *args
    matching = 0
    i = 0
    while true
      if matching == args.count
        replacement = yield(@body.slice(i - args.count, args.count))
        @body = @body.slice(0, i - args.count) +
          replacement +
          @body.slice(i, @body.count)
        i = 0 #i - args.count - 1 + replacement.count
        matching = 0
      end
      break if i >= @body.count
      item = @body[i]
      if match_instruction(item, args[matching])
        matching += 1
      else
        matching = 0
      end
      i += 1
    end
  end
  
  ## work
  def method_definitions
    replace_sequence(
      [:putspecialobject, 1],
      [:putspecialobject, 2],
      [:putobject, "+"],
      [:putiseq, "+"],
      [:send, :"core#define_method", "*"],
      [:pop]) do |found|
      name = found[2][1]
      [
        [:custom_defmethod, name, found[3][1]]
        ]
    end
  end
  
  def smethod_definitions
    replace_sequence(
      [:putspecialobject, 1],
      [:putself],
      [:putobject, "+"],
      [:putiseq, "+"],
      [:send, :"core#define_singleton_method", "*"]
      ) do |found|
      name = found[2][1]
      [
        [:custom_defsmethod, name, found[3][1]]
        ]
    end
  end
  
  def proc_definitions
    replace_sequence(
      [:putnil],
      [:getconstant, :Proc],
      [:send, :new, "+"]) do |found|
      [
        [:custom_newproc, 0, found[2][3]]
        ]
    end
  end

  def class_definitions
    replace_sequence(
      [:putspecialobject, 3],
      [:putnil],
      [:defineclass, "+"]) do |found|
        name = found[2][1]
        [
          [:custom_defclass, name, found[2][2]]
          ]
      end
  end
  
  def process
    #method_definitions
    #smethod_definitions
    proc_definitions
    #class_definitions
    @iseq[13] = @body
  end
end