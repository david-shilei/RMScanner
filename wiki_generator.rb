require 'method_source'

class WikiGenerator
  def initialize(file_name = 'output_wiki')
    @file = File.open(file_name, 'w')
    # ObjectSpace.define_finalizer(self, proc { file.close })
  end
  
  def add_head(text)
    @file.puts("== #{text} ==") 
  end
  
  def add_subhead(text)
    @file.puts("=== #{text} ===") 
  end
  
  def add_codes_block(text)
    lines = text.split("\n")
    lines.each do |line|
      @file.puts(" #{line}")
    end
  end
  
  def add_text(text, options = {})
    if(options[:bold] && options[:italic])
      content = "'''''#{text}'''''"
    elsif options[:italic]
      content = "''#{text}''"
    elsif options[:bold]
      content = "'''#{text}'''"
    else
      content = text
    end
    @file.puts(content)
  end  
  
  def add_empty_line
    @file.puts("\n")
  end
  
  def close
    @file.close
  end
end