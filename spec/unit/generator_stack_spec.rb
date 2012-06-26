require File.expand_path('../../spec_helper', __FILE__)

class StackOutput < StringIO
  def exec str
    self.write(str+"\n")
  end
end

describe GeneratorStack do
  it "push pop ok" do
    output = StackOutput.new
    s = GeneratorStack.new(output, 100)
    s.push("v1")
    s.commit
    s.push("v2")

    s.pop_lucky.should eq("v2")
    s.pop_lucky.should eq("sp[rsp-1]")

    output.exec "CMD #{s}"

    s.commit

    output.string.should eq("YARV_PUTOBJECT(v1, sp[rsp++]);\nCMD sp[rsp-1]\nrsp-=1;\n")
  end

  it "push pop ok 2" do
    output = StackOutput.new
    s = GeneratorStack.new(output, 100)
    s.push("v1")
    s.push("v2")
    s.commit

    s.pop_lucky.should eq("sp[rsp-1]")
    s.pop_lucky.should eq("sp[rsp-2]")

    output.exec "CMD #{s}"

    s.commit

    output.string.should eq("YARV_PUTOBJECT(v1, sp[rsp++]);\n" +
      "YARV_PUTOBJECT(v2, sp[rsp++]);\nCMD sp[rsp-2]\nrsp-=2;\n")
  end

  it "push pop ok 3" do
    output = StackOutput.new
    s = GeneratorStack.new(output, 100)
    s.push("v1")
    s.push("v2")

    s.pop_lucky.should eq("v2")
    s.pop_lucky.should eq("v1")

    output.exec "CMD #{s}"

    s.commit

    output.string.should eq("CMD sp[rsp+0]\n")
  end
end