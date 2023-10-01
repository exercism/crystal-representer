require "compiler/crystal/syntax"

# :nodoc:
class TestVisitor < Crystal::Transformer
  @@counter = 1
  @@data = [] of String

  @@debug = [] of Tuple(String, String)

  def self.debug : Array(Tuple(String, String))
    @@debug
  end

  def initialize(data = [] of String, debug = [] of Tuple(String, String))
    {% if flag?(:Debug) %}
      @@debug += debug
    {% end %}
    @@data += data
    @@counter += data.size
  end

  def self.data : Array(String)
    @@data
  end

  def initialize(data = [] of String, debug = [] of Tuple(String, String))
    @@debug += debug
    @@data += data
    @@counter += data.size
  end

  def transform(node : Crystal::Def)
    temp = node.block_arg
    unless temp.nil?
      node.block_arg = temp.transform(TestVisitor.new)
    end

    node.name = re_name(node.name)
    node.args = node.args.map do |arg|
      arg.transform(TestVisitor.new)
    end
    node.body = node.body.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::Arg)
    node.external_name = re_name_or_add(node.external_name, node)
    node.name = re_name_or_add(node.name, node)
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
    node.name = re_name(node.name)
    node
  end

  def transform(node : Crystal::Macro)
    temp = node.block_arg
    unless temp.nil?
      node.block_arg = temp.transform(TestVisitor.new)
    end

    node.name = re_name(node.name)
    node.args = node.args.map do |arg|
      arg.transform(TestVisitor.new)
    end
    node.body = node.body.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::ClassVar)
    node.name = re_name_or_add(node.name[2..], node, 2)
    node
  end

  def transform(node : Crystal::InstanceVar)
    node.name = re_name_or_add(node.name[1..], node, 1)
    node
  end

  def transform(node : Crystal::Assign)
    a_count = node.target.to_s.chars.take_while { |c| c == '@' }.size
    node.target = Crystal::Parser.new(re_name_or_add(node.target.to_s[a_count..], node, a_count)).parse
    node.value = node.value.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::ModuleDef)
    node.name = re_path(node.name)
    node.body = node.body.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::ClassDef)
    temp = node.superclass
    unless temp.nil?
      node.superclass = temp.transform(TestVisitor.new)
    end
    node.name = re_path(node.name)
    node.body = node.body.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::EnumDef)
    node.name = re_path(node.name)
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
    data = [] of Crystal::ASTNode
    node.type_vars.each do |type_var|
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
    temp = node.exp
    unless temp.nil?
      node.exp = temp.transform(TestVisitor.new)
    end
    node.body = node.body.transform(TestVisitor.new)
    node
  end

  def transform(node : Crystal::MacroLiteral)
    if (node.value.includes?("case") || node.value.includes?("else") || node.value.includes?("def") || node.value.includes?("if") || node.value.includes?("elsif") || node.value.includes?("unless") || node.value.includes?("when")) && !node.value.includes?("end")
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
          temp = Crystal::Parser.new(line.gsub(/case |else|end|if |when |unless |elsif |def /) do |match|
            keywords_removed = match
            ""
          end)
          "#{" " * spaces_start}#{keywords_removed}#{temp.parse.transform(TestVisitor.new)}"
        end
      end.join("\n")
    elsif node.value =~ /^[ \n]*$/
      nil
    elsif node.value.strip != "end"
      node.value = node.value.split("\n").map do |line|
        spaces_start = 0
        keywords_removed_left = ""
        keywords_removed_right = ""
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
          line = line.strip
          if line[-1] == '"' && line[-2] == '['
            line = line[..-3]
            keywords_removed_right = "[\""
          elsif line[-1] == '"'
            line = line[..-2]
            keywords_removed_right = "\""
          end
          if line[0] == '"' && line[1] == ']'
            line = line[2..]
            keywords_removed_left = "\"]"
          elsif line[0] == '"'
            line = line[1..]
            keywords_removed_left = "\""
          end
          "#{" " * spaces_start}#{keywords_removed_left}#{Crystal::Parser.new(line).parse.transform(TestVisitor.new)}#{keywords_removed_right}"
        end
      end.join("\n")
    end
    node
  end

  def transform(node : Crystal::MacroExpression)
    p node.exp.transform self
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
      node.block = temp.transform(TestVisitor.new)
    end

    temp = node.named_args
    unless temp.nil?
      node.named_args = temp.map { |arg| arg.transform(TestVisitor.new).as(Crystal::NamedArgument) }
    end

    unless node.args.empty?
      node.args = node.args.map do |arg|
        result : Crystal::ASTNode = Crystal::Parser.new("").parse
        if {"getter", "setter", "property"}.includes?(node.name) && arg.is_a?(Crystal::SymbolLiteral)
          result = Crystal::Parser.new(":#{Crystal::Parser.new(arg.to_s[1..]).parse.transform(TestVisitor.new)}").parse
        else
          result = arg.transform(TestVisitor.new).as(Crystal::ASTNode)
        end
        result
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
    node.name = re_name(node.name)
    node
  end

  def transform(node : Crystal::Alias)
    node.value = node.value.transform(TestVisitor.new)
    node.name = re_path_or_add(node.name, node)
    node
  end

  def transform(node : Crystal::Union)
    node.types = node.types.map do |type|
      re_path(type.as(Crystal::Path)).as(Crystal::ASTNode)
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
    node
  end

  def transform(node : Crystal::ProcNotation)
    temp = node.inputs
    unless temp.nil?
      node.inputs = temp.map do |input|
        input = Crystal::Parser.new(re_name(input.to_s)).parse
        input.as(Crystal::ASTNode)
      end
    end
    unless node.output.nil?
      node.output = Crystal::Parser.new(re_name(node.output.to_s)).parse
    end
    node
  end

  def transform(node : Crystal::Path)
    node.names = node.names.map do |name|
      re_name(name)
    end
    node
  end

  private def re_name(name : String) : String
    if @@data.includes?(name)
      location = @@data.index(name)
      unless location.nil?
        name = "PLACEHOLDER_#{location + 1}"
      end
    end
    name
  end

  private def re_name_or_add(name : String, called_from : Crystal::ASTNode, a_count = 0) : String
    if @@data.includes?(name)
      location = @@data.index(name)
      unless location.nil?
        name = "#{"@" * a_count}PLACEHOLDER_#{location + 1}"
      end
    else
      @@debug << {name, called_from.class.to_s}
      @@data << name
      name = "#{"@" * a_count}PLACEHOLDER_#{@@counter}"
      @@counter += 1
    end
    name
  end

  private def re_path(name : Crystal::Path) : Crystal::Path
    if @@data.includes?(name.to_s)
      location = @@data.index(name.to_s)
      unless location.nil?
        name = Crystal::Path.new(["PLACEHOLDER_#{location + 1}"])
      end
    end
    name
  end

  private def re_path_or_add(name : Crystal::Path, called_from : Crystal::ASTNode) : Crystal::Path
    if @@data.includes?(name.to_s)
      location = @@data.index(name.to_s)
      unless location.nil?
        name = Crystal::Path.new("PLACEHOLDER_#{location + 1}")
      end
    else
      @@debug << {name.to_s, called_from.class.to_s}
      @@data << name.to_s
      name = Crystal::Path.new("PLACEHOLDER_#{@@counter}")
      @@counter += 1
    end
    name
  end
end

# :nodoc:
class TestVisitor_2 < Crystal::Visitor
  alias Def = Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil, Int32?, Bool)

  property counter, methods, debug

  @debug : Array(Tuple(String, String)) = Array(Tuple(String, String)).new

  ExpectedNames = ["self", "->"]

  def initialize
    @counter = [] of String
    @methods = Array(Array(Def)).new
    @methods << [] of Def
    @insde_method = 0
  end

  {% for name in %w(ClassDef Macro ModuleDef CStructOrUnionDef EnumDef) %}
    def visit(node : Crystal::{{name.id}})
      @methods << [] of Def
      add_name(node)
      true
    end

    def end_visit(node : Crystal::{{name.id}})
      @methods << [] of Def
    end
  {% end %}

  def visit(node : Crystal::Def)
    add_name(node)
    if @insde_method == 0
      @methods[-1] << {node.name, node.body, node.block_arg, node.args, node.receiver, node.visibility, node.return_type, node.block_arity, node.calls_initialize?}
    end
    @insde_method += 1
    true
  end

  def end_visit(node : Crystal::Def)
    @insde_method -= 1
    true
  end

  def visit(node : Crystal::VisibilityModifier)
    if node.exp.is_a?(Crystal::Def)
      node.exp.visibility = node.modifier
    end
    true
  end

  def visit(node : Crystal::Var)
    add_name(node)
    true
  end

  def visit(node)
    true
  end

  private def add_name(node : Crystal::ASTNode)
    unless @counter.includes?(node.name.to_s) || ExpectedNames.includes?(node.name.to_s)
      @debug << {node.name.to_s, node.class.to_s}
      @counter << node.name.to_s
    end
  end
end

# :nodoc:
class Reformat < Crystal::Transformer
  alias Def = Tuple(String, Crystal::ASTNode, Crystal::Arg | Nil, Array(Crystal::Arg), Crystal::ASTNode | Nil, Crystal::Visibility, Crystal::ASTNode | Nil, Int32?, Bool)
  @data : Array(Array(Def))

  def initialize(data)
    @data = data.map { |x| x.sort { |a, b| a[0] <=> b[0] } }
    @counter = 0
    @counter_2 = 0
  end

  def transform(node : Crystal::VisibilityModifier)
    return node unless node.exp.is_a?(Crystal::Def)
    if @data[@counter_2][@counter][5] == Crystal::Visibility::Private || @data[@counter_2][@counter][5] == Crystal::Visibility::Protected
      node.modifier = @data[@counter_2][@counter][5]
      node.exp.transform self
      node
    else
      data = Crystal::Def.new(@data[@counter_2][@counter][0], @data[@counter_2][@counter][3], @data[@counter_2][@counter][1], @data[@counter_2][@counter][4], @data[@counter_2][@counter][2], @data[@counter_2][@counter][6], false, @data[@counter_2][@counter][7])
      @counter += 1
      data
    end
  end

  {% for name in %w(ClassDef Macro ModuleDef) %}
    def transform(node : Crystal::{{name.id}})
      @counter = 0
      @counter_2 += 1
      node.body = node.body.transform(self)
      @counter = 0
      @counter_2 += 1
      node
    end
  {% end %}

  def transform(node : Crystal::EnumDef)
    @counter = 0
    @counter_2 += 1
    node
  end

  def transform(node : Crystal::Def)
    if @data[@counter_2][@counter][5] == Crystal::Visibility::Private || @data[@counter_2][@counter][5] == Crystal::Visibility::Protected
      new_def = Crystal::Def.new(@data[@counter_2][@counter][0], @data[@counter_2][@counter][3], @data[@counter_2][@counter][1], @data[@counter_2][@counter][4], @data[@counter_2][@counter][2], @data[@counter_2][@counter][6], false, @data[@counter_2][@counter][7])
      new_def.calls_initialize = @data[@counter_2][@counter][8]
      data = Crystal::VisibilityModifier.new(@data[@counter_2][@counter][5], new_def)
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
      node.block_arity = @data[@counter_2][@counter][7]
      node.calls_initialize = @data[@counter_2][@counter][8]
      @counter += 1
      node
    end
  end
end
