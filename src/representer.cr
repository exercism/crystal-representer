require "compiler/crystal/syntax"
require "json"

input_dir = ARGV[0]?
config_file = ARGV[1]?
representation_file = ARGV[2]?
mapping_file = ARGV[3]?

class TestVisitor < Crystal::Transformer
  @@counter = 1
  @@data = [] of String
  @@temp = Array(Array(String)).new

  def initialize(data = [] of String)
    @@data += data
    @@counter += data.size
  end

  def self.data : Array(String)
    @@data
  end

  def transform(node : Crystal::Def)
    temp = node.block_arg
    unless temp.nil?
      node.block_arg = temp.transform(TestVisitor.new)
    end

    if @@data.includes?(node.name)
      location = @@data.index(node.name)
      unless location.nil?
        node.name = "PLACEHOLDER_#{location + 1}"
      end
    else
      @@data << node.name
      @@temp << [node.name, "PLACEHOLDER_#{@@counter}", "def"]
      node.name = "PLACEHOLDER_#{@@counter}"
      @@counter += 1
    end
    node.args = node.args.map do |arg|
      arg.transform(TestVisitor.new)
    end
    node.body = node.body.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::Arg)
    if @@data.includes?(node.external_name)
      location = @@data.index(node.external_name)
      unless location.nil?
        node.external_name = "PLACEHOLDER_#{location + 1}"
      end
    else
      @@data << node.external_name
      @@temp << [node.external_name, "PLACEHOLDER_#{@@counter}", "arg"]
      node.external_name = "PLACEHOLDER_#{@@counter}"
      @@counter += 1
    end

    if @@data.includes?(node.name)
      location = @@data.index(node.name)
      unless location.nil?
        node.name = "PLACEHOLDER_#{location + 1}"
      end
    else
      @@data << node.name
      @@temp << [node.name, "PLACEHOLDER_#{@@counter}", "arg"]
      node.name = "PLACEHOLDER_#{@@counter}"
      @@counter += 1
    end
    if @@data.includes?(node.restriction.to_s)
      location = @@data.index(node.restriction.to_s)
      unless location.nil?
        node.restriction = Crystal::Parser.new("PLACEHOLDER_#{location + 1}").parse
      end
    else
      temp = node.restriction
      unless temp.nil?
        node.restriction = temp.transform(TestVisitor.new)
      end
    end

    node
  end

  def transform(node : Crystal::Var)
    if @@data.includes?(node.name)
      location = @@data.index(node.name)
      unless location.nil?
        node.name = "PLACEHOLDER_#{location + 1}"
      end
    else
      @@data << node.name
      @@temp << [node.name, "PLACEHOLDER_#{@@counter}", "var"]
      node.name = "PLACEHOLDER_#{@@counter}"
      @@counter += 1
    end
    node
  end

  def transform(node : Crystal::ClassVar)
    if @@data.includes?(node.name)
      location = @@data.index(node.name)
      unless location.nil?
        node.name = "@@PLACEHOLDER_#{location + 1}"
      end
    else
      @@data << node.name
      @@temp << [node.name, "@@PLACEHOLDER_#{@@counter}", "class_var"]
      node.name = "@@PLACEHOLDER_#{@@counter}"
      @@counter += 1
    end
    node
  end

  def transform(node : Crystal::InstanceVar)
    if @@data.includes?(node.name[1..])
      location = @@data.index(node.name[1..])
      unless location.nil?
        node.name = "@PLACEHOLDER_#{location + 1}"
      end
    else
      @@data << node.name[1..]
      @@temp << [node.name[1..], "@PLACEHOLDER_#{@@counter}", "instance_var"]
      node.name = "@PLACEHOLDER_#{@@counter}"
      @@counter += 1
    end
    node
  end

  def transform(node : Crystal::Assign)
    case node.target.to_s
    when /^@@/
      temp = node.target.to_s[2..]
    when /^@/
      temp = node.target.to_s[1..]
    else
      temp = node.target.to_s
    end
    if @@data.includes?(temp)
      location = @@data.index(temp)
      unless location.nil?
        case node.target.to_s
        when /^@@/
          node.target = Crystal::Parser.new("@@PLACEHOLDER_#{location + 1}").parse
        when /^@/
          node.target = Crystal::Parser.new("@PLACEHOLDER_#{location + 1}").parse
        else
          node.target = Crystal::Parser.new("PLACEHOLDER_#{location + 1}").parse
        end
      end
    else
      @@data << temp
      @@temp << [temp, "PLACEHOLDER_#{@@counter}", "assign"]
      case node.target.to_s
      when /^@@/
        node.target = Crystal::Parser.new("@@PLACEHOLDER_#{@@counter}").parse
      when /^@/
        node.target = Crystal::Parser.new("@PLACEHOLDER_#{@@counter}").parse
      else
        node.target = Crystal::Parser.new("PLACEHOLDER_#{@@counter}").parse
      end
      @@counter += 1
    end
    node.value = node.value.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::ModuleDef)
    if @@data.includes?(node.name.to_s)
      location = @@data.index(node.name.to_s)
      unless location.nil?
        node.name = Crystal::Path.new(["PLACEHOLDER_#{location + 1}"])
      end
    else
      @@data << node.name.to_s
      @@temp << [node.name.to_s, "PLACEHOLDER_#{@@counter}", "module"]
      node.name = Crystal::Path.new(["PLACEHOLDER_#{@@counter}"])
      @@counter += 1
    end
    node.body = node.body.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::ClassDef)
    temp = node.superclass
    unless temp.nil?
      node.superclass = temp.transform(TestVisitor.new)
    end
    if @@data.includes?(node.name.to_s)
      location = @@data.index(node.name.to_s)
      unless location.nil?
        node.name = Crystal::Path.new(["PLACEHOLDER_#{location + 1}"])
      end
    else
      @@data << node.name.to_s
      @@temp << [node.name.to_s, "PLACEHOLDER_#{@@counter}", "class"]
      node.name = Crystal::Path.new(["PLACEHOLDER_#{@@counter}"])
      @@counter += 1
    end
    node.body = node.body.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::EnumDef)
    if @@data.includes?(node.name.to_s)
      location = @@data.index(node.name.to_s)
      unless location.nil?
        node.name = Crystal::Path.new(["PLACEHOLDER_#{location + 1}"])
      end
    else
      @@data << node.name.to_s
      @@temp << [node.name.to_s, "PLACEHOLDER_#{@@counter}", "enum"]
      node.name = Crystal::Path.new(["PLACEHOLDER_#{@@counter}"])
      @@counter += 1
    end
    node.members = node.members.map do |line|
      unless line.nil?
        if line.to_s.includes?("def")
          line = line.transform(TestVisitor.new)
        else
          line
        end
      else
        Crystal::Parser.new("").parse
      end
    end
    node
  end

  def transform(node : Crystal::Generic)
    # p @@data
    data = [] of Crystal::ASTNode
    node.type_vars.each do |type_var|
      # p type_var
      data << type_var.transform(TestVisitor.new)
    end
    node.type_vars = data
    node
  end

  def transform(node : Crystal::MacroIf)
    node.then = node.then.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::MacroFor)
    node.vars.map { |var| var.transform(TestVisitor.new).as(Crystal::ASTNode) }
    node.body
    node
  end

  def transform(node : Crystal::MacroLiteral)
    if (node.value.includes?("case") || node.value.includes?("else")) && !node.value.includes?("end")
      node.value = node.value.split("\n").map do |line|
        spaces_start = 0
        keywords_removed = ""
        line.each_char do |char|
          if char == ' '
            spaces_start += 1
          else
            break
          end
        end
        if line.chars.all? { |char| char == ' ' }
          line
        else
          temp = Crystal::Parser.new(line.gsub(/case |else|end|if |when |unless |elsif /) do |match|
            keywords_removed = match
            ""
          end)
          "#{" " * spaces_start}#{keywords_removed}#{temp.parse.transform(TestVisitor.new)}"
        end
      end.join("\n")
    elsif node.value =~ /^[ \n]*$/
      nil
    elsif node.value.strip != "end"
      node = Crystal::Parser.new(node.value).parse.transform(TestVisitor.new)
    end
    node
  end

  def transform(node : Crystal::MacroExpression)
    node
  end

  def transform(node : Crystal::MacroVar)
    node
  end

  def transform(node : Crystal::Case)
    temp = node.cond
    unless temp.nil?
      node.cond = temp.transform(TestVisitor.new)
    end
    node
  end

  def transform(node : Crystal::Call)
    temp = node.block
    unless temp.nil?
      # p node.block
      node.block = temp.transform(TestVisitor.new)
      # p node.block
    end

    temp = node.named_args
    unless temp.nil?
      # p node.named_args
      node.named_args = temp.map { |arg| arg.transform(TestVisitor.new).as(Crystal::NamedArgument) }
      # p node.named_args
    end

    unless node.args.empty?
      node.args = node.args.map do |arg|
        arg.transform(TestVisitor.new).as(Crystal::ASTNode)
      end
    end
    temp = node.obj
    unless temp.nil?
      unless temp == Crystal::Parser.new("self").parse
        if @@data.includes?(node.obj.to_s)
          location = @@data.index(node.obj.to_s)
          unless location.nil?
            node.obj = Crystal::Parser.new("PLACEHOLDER_#{location + 1}").parse
          end
        else
          node.obj = temp.transform(TestVisitor.new)
        end
      end
    end
    if @@data.includes?(node.name)
      location = @@data.index(node.name)
      unless location.nil?
        node.name = "PLACEHOLDER_#{location + 1}"
      end
    end
    node
  end

  def transform(node : Crystal::Var)
    if @@data.includes?(node.name)
      location = @@data.index(node.name)
      unless location.nil?
        node.name = "PLACEHOLDER_#{location + 1}"
      end
    else
      @@data << node.name
      @@temp << [node.name, "PLACEHOLDER_#{@@counter}", "var"]
      node.name = "PLACEHOLDER_#{@@counter}"
      @@counter += 1
    end
    node
  end

  def transform(node : Crystal::Asm)
    p node
    node
  end

  def transform(node : Crystal::Alias)
    node.value = node.value.transform(TestVisitor.new)
    if @@data.includes?(node.name.to_s)
      location = @@data.index(node.name.to_s)
      unless location.nil?
        node.name = Crystal::Path.new("PLACEHOLDER_#{location + 1}")
      end
    else
      @@data << node.name.to_s
      @@temp << [node.name.to_s, "PLACEHOLDER_#{@@counter}", "alias"]
      node.name = Crystal::Path.new("PLACEHOLDER_#{@@counter}")
      @@counter += 1
    end
    node
  end

  def transform(node : Crystal::TypeOf)
    p node
    node
  end

  def transform(node : Crystal::CStructOrUnionDef)
    p node
    node
  end

  def transform(node : Crystal::TypeDef)
    p node
    node
  end

  def transform(node : Crystal::Union)
    node.types = node.types.map do |type|
      if @@data.includes?(type.to_s)
        location = @@data.index(type.to_s)
        unless location.nil?
          type = Crystal::Path.new("PLACEHOLDER_#{location + 1}")
        end
      end
      type.as(Crystal::ASTNode)
    end
    node
  end

  def transform(node : Crystal::TypeDeclaration)
    node.var = node.var.transform(TestVisitor.new)
    if @@data.includes?(node.declared_type.to_s)
      location = @@data.index(node.declared_type.to_s)
      unless location.nil?
        node.declared_type = Crystal::Path.new("PLACEHOLDER_#{location + 1}")
      end
    else
      temp = node.declared_type
      unless temp.nil?
        node.declared_type = temp.transform(TestVisitor.new)
      end
    end
    node.declared_type
    node
  end

  def transform(node : Crystal::PointerOf)
    p node
    node
  end

  def transform(node : Crystal::Asm)
    p node
    node
  end

  def transform(node : Crystal::ProcNotation)
    temp = node.inputs
    unless temp.nil?
      node.inputs = temp.map do |input|
        if @@data.includes?(input.to_s)
          location = @@data.index(input.to_s)
          unless location.nil?
            input = Crystal::Parser.new("PLACEHOLDER_#{location + 1}").parse
          end
        else
          @@data << input.to_s
          @@temp << [input.to_s, "PLACEHOLDER_#{@@counter}", "proc"]
          input = Crystal::Parser.new("PLACEHOLDER_#{@@counter}").parse
          @@counter += 1
        end
        input.as(Crystal::ASTNode)
      end
    end
    unless node.output.nil?
      if @@data.includes?(node.output.to_s)
        location = @@data.index(node.output.to_s)
        unless location.nil?
          node.output = Crystal::Parser.new("PLACEHOLDER_#{location + 1}").parse
        end
      else
        @@data << node.output.to_s
        @@temp << [node.output.to_s, "PLACEHOLDER_#{@@counter}", "proc"]
        node.output = Crystal::Parser.new("PLACEHOLDER_#{@@counter}").parse
        @@counter += 1
      end
    end
    node
  end

  def transform(node : Crystal::Path)
    node.names = node.names.map do |name|
      if @@data.includes?(name)
        location = @@data.index(name)
        unless location.nil?
          name = "PLACEHOLDER_#{location + 1}"
        end
      end
      name
    end
    node
  end
end

class TestVisitor_2 < Crystal::Visitor
  property counter
  property methods

  def initialize
    @counter = [] of String
    @methods = Array(Array(Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil))).new
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
  end

  def visit(node : Crystal::ClassDef)
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
    unless @counter.includes?(node.to_s)
      @counter << node.name.to_s
    end
    true
  end

  def end_visit(node : Crystal::ClassDef)
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
  end

  def visit(node : Crystal::CStructOrUnionDef)
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
    unless @counter.includes?(node.to_s)
      @counter << node.name.to_s
    end
    true
  end

  def end_visit(node : Crystal::CStructOrUnionDef)
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
  end

  def visit(node : Crystal::EnumDef)
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
    unless @counter.includes?(node.to_s)
      @counter << node.name.to_s
    end
    true
  end

  def end_visit(node : Crystal::EnumDef)
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
  end

  def visit(node : Crystal::ModuleDef)
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
    unless @counter.includes?(node.to_s)
      @counter << node.name.to_s
    end
    true
  end

  def end_visit(node : Crystal::ModuleDef)
    @methods << [] of Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)
  end

  def visit(node : Crystal::Def)
    # p node.name
    # p node.visibility
    unless @counter.includes?(node.to_s)
      @counter << node.name.to_s
    end
    @methods[-1] << {node.name, node.body, node.block_arg, node.args, node.receiver, node.visibility, node.return_type}
    true
  end

  def visit(node : Crystal::VisibilityModifier)
    node.exp.visibility = node.modifier
    true
  end

  def visit(node : Crystal::Var)
    unless @counter.includes?(node.name) || node.name == "self"
      @counter << node.name
    end
    true
  end

  def visit(node)
    true
  end
end

class Reformat < Crystal::Transformer
  @data : Array(Array(Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil)))

  def initialize(data)
    @data = data.map { |x| x.sort { |a, b| a[0] <=> b[0] } }
    # @data = Array(Array(Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil))).new
    @counter = 0
    @counter_2 = 0
  end

  def transform(node : Crystal::VisibilityModifier)
    if @data[@counter_2][@counter][5] == Crystal::Visibility::Private || @data[@counter_2][@counter][5] == Crystal::Visibility::Protected
      node.modifier = @data[@counter_2][@counter][5]
      node.exp.transform self
      node
    else
      data = Crystal::Def.new(@data[@counter_2][@counter][0], @data[@counter_2][@counter][3], @data[@counter_2][@counter][1], @data[@counter_2][@counter][4], @data[@counter_2][@counter][2], @data[@counter_2][@counter][6])
      @counter += 1
      data
    end
  end

  def transform(node : Crystal::ClassDef)
    @counter = 0
    @counter_2 += 1
    node.body = node.body.transform(self)
    @counter = 0
    @counter_2 += 1
    node
  end

  def transform(node : Crystal::ModuleDef)
    @counter = 0
    @counter_2 += 1
    node.body = node.body.transform(self)
    @counter = 0
    @counter_2 += 1
    node
  end

  def transform(node : Crystal::EnumDef)
    @counter = 0
    @counter_2 += 1
    node
  end

  def transform(node : Crystal::Def)
    if @data[@counter_2][@counter][5] == Crystal::Visibility::Private || @data[@counter_2][@counter][5] == Crystal::Visibility::Protected
      data = Crystal::VisibilityModifier.new(@data[@counter_2][@counter][5], Crystal::Def.new(@data[@counter_2][@counter][0], @data[@counter_2][@counter][3], @data[@counter_2][@counter][1], @data[@counter_2][@counter][4], @data[@counter_2][@counter][2], @data[@counter_2][@counter][6]))
      @counter += 1
      data
    else
      node.name = @data[@counter_2][@counter][0]
      node.body = @data[@counter_2][@counter][1]
      node.block_arg = @data[@counter_2][@counter][2]
      node.args = @data[@counter_2][@counter][3]
      node.receiver = @data[@counter_2][@counter][4]
      node.visibility = @data[@counter_2][@counter][5]
      node.return_type = @data[@counter_2][@counter][6]
      @counter += 1
      node
    end
  end
end

unless config_file.nil?
  names = [] of String
  solution = ""
  unless input_dir.nil?
    solution_files = JSON.parse(File.read(config_file))["files"]["solution"].as_a
    solution_files.each do |file|
      "#{input_dir}/#{file}"
      raise "Can't find #{input_dir}/#{file}" unless File.exists?("#{input_dir}/#{file}")
      solution += File.read("#{input_dir}/#{file}")
    end
    begin
    solution += "\n"
    parser = Crystal::Parser.new(solution)
    ast = parser.parse
    abc = TestVisitor_2.new
    abc.accept(ast)
    ast = ast.transform(Reformat.new(abc.methods))
    trans = ast.transform(TestVisitor.new(abc.counter))
    rescue
      p solution[0..-2]
      trans = solution[0..-2]
    end
    json = Hash(String, String).new
  
    TestVisitor.data.each_with_index do |x, i|
      json["PLACEHOLDER_#{i + 1}"] = x
    end
  end
end

json = json.to_json
unless representation_file.nil?
  puts "write representation_file"
  File.write(representation_file, trans.to_s)
else
  puts "Can't find file"
end
unless mapping_file.nil?
  puts "write json"
  File.write(mapping_file, json.to_s)
else
  puts "Can't find file"
end
