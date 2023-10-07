require "./representer"
require "json"
require "compiler/crystal/syntax"

# Representer allows to be integrated with other programs easilly through its API.
#
# ```
# represent = Representer.new
# represent.parse_string("def foo\n  1 + 1\nend")
# represent.represent
# represent.representation
# # => "def PLACEHOLDER_1\n  1 + 1\nend"
# ```
class Representer
  @ast : Crystal::ASTNode = Crystal::Parser.new("").parse
  @solution : String = ""
  @representation : String = ""

  getter representation : String, ast : Crystal::ASTNode

  # Parses all files in a folder by grouping them into a single long `String`
  # and then parsing that `String` with the Crystal parser.
  #
  # ```
  # path = Path.new("path/to/folder")
  # represent = Representer.new
  # represent.parse_folder(path)
  # ```
  def parse_folder(folder : Path)
    raise "Can't find #{folder}" unless Dir.exists?(folder)
    @solution = ""
    Dir.open(folder).each_child do |file|
      @solution += File.read(folder / file)
    end
    @ast = parse(@solution)
  end

  # Parses a single file by reading it and then parsing it with the Crystal
  # parser.
  #
  # ```
  # path = Path.new("path/to/file")
  # represent = Representer.new
  # represent.parse_file(path)
  # ```
  def parse_file(file : Path)
    raise "Can't find #{file}" unless File.exists?(file)
    @solution = File.read(file)
    @ast = parse(@solution)
  end

  # Parses a `String` by parsing it with the Crystal parser.
  #
  # ```
  # represent = Representer.new
  # represent.parse_string("def foo\n  1 + 1\nend")
  # ```
  def parse_string(content : String)
    @ast = parse(content)
  end

  # Transforms the AST into a representation.
  def represent
    begin
    visitor = TestVisitor_2.new
    visitor.accept(@ast)
    transformed_ast = @ast.transform(Reformat.new(visitor.methods))
    visitor_2 = TestVisitor_2.new
    visitor_2.accept(ast)
    @representation = @ast.transform(TestVisitor.new(visitor_2.counter, visitor_2.debug)).to_s
    rescue error
      puts error
      @representation = @solution
    end
  end

  # Returns a mapping of the replaced names to the original names.
  # The format returned is a json formatted `String`.
  #
  # ```
  # represent = Representer.new
  # represent.parse_string("def foo\n  1 + 1\nend")
  # represent.represent
  # represent.mapping
  # # => "{\"PLACEHOLDER_1\":\"foo\"}"
  def mapping_json : String
    json = Hash(String, String).new

    TestVisitor.data.each_with_index do |x, i|
      json["PLACEHOLDER_#{i + 1}"] = x
    end
    json.to_json
  end

  # Returns a version number for the representation format.
  # The format returned is a json formatted `String`.
  #
  # ```
  # represent = Representer.new
  # represent.parse_string("def foo\n  1 + 1\nend")
  # represent.represent
  # represent.representation_json
  # # => "{\"version\":1}"
  def representation_json : String
    {"version" => 1}.to_json
  end

  # Returns a json formatted `String` with the debug information.
  #
  # ```
  # represent = Representer.new
  # represent.parse_string("def foo\n  1 + 1\nend")
  # represent.represent
  # represent.debug_json
  # # => "[["PLACEHOLDER_1", "Crystal::Def"]]"
  def debug_json : String
    TestVisitor.debug.to_json
  end

  private def parse(content : String) : Crystal::ASTNode
    content += "\n"
    parser = Crystal::Parser.new(content)
    parser.parse
  end
end
