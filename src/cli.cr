require "option_parser"
require "./api"

options = Hash(Symbol, (String | Bool | Path | Nil)){
  :output       => nil,
  :debug        => false,
  :version_file => false,
}

representer = Representer.new

OptionParser.parse do |parser|
  parser.banner = "Welcome to The Crystal Representer!"

  parser.on "-v", "--version", "Show version" do
    puts "version 1.2"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.on "-f FILE", "--file FILE", "File to parse" do |file|
    puts "Parsing file: #{file}"
    path = Path.new(file)
    representer.parse_file(path)
    puts "Done!"
  end

  parser.on "-d DIRECTORY", "--directory DIRECTORY", "Directory to parse" do |directory|
    puts "Parsing directory #{directory}"
    path = Path.new(directory)
    representer.parse_folder(path)
    puts "Done!"
  end

  parser.on "--debug", "Debug mode" do
    puts "Debug mode enabled"
    options[:debug] = true
    puts "Done!"
  end

  parser.on "-o DIRECTORY", "--output DIRECTORY", "Output directory" do |directory|
    puts "Outputting to directory #{directory}"
    if directory.is_a? String
      options[:output] = Path.new(directory)
    else
      raise "Output directory must be a string"
    end
    puts "Done!"
  end
end

directory = options[:output]

unless directory.is_a?(Path)
  puts "No output directory specified"
  exit 0
end

representer.represent
File.write(directory / "mapping.json", representer.mapping_json)
File.write(directory / "representation.json", representer.representation_json)
File.write(directory / "representation.txt", representer.representation)

if options[:debug]
  File.write(directory / "debug.json", representer.debug_json)
end 
