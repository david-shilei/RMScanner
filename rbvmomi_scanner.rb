require 'rbvmomi'
require 'method_source'
require 'pry'
load 'wiki_generator.rb'

METHODS_SOURCE_CODES_COMMENT = "Source codes:"
PUBLIC_INSTANCE_METHODS = "Public Instance Methods"
PUBLIC_METHODS = "Public Methods"
PUBLIC_CLASS_METHODS = "Public Class Methods"
CLASS_VARIABLES = "Class Variables"
INSTANCE_VARIABLES = "Instance Variables"

class RbVmomiScanner
  def initialize
    @wiki = WikiGenerator.new
    @scanned_objects = []
  end
  
  # convert methods to wiki content
  def methods_to_wiki_from_object(methods, obj, type_str)
    return if methods.empty?
    @wiki.add_subhead(type_str)
    @wiki.add_empty_line
    
    # get the attached info for dynamically generated methods
    full_methods_desc = (obj.respond_to? :full_methods_desc) ? obj.full_methods_desc : {}
    
    methods.each { |sym|
      begin
        method = nil
        if obj.methods.include? sym # it's class method
          method = obj.method(sym)
        elsif obj.instance_methods.include?(sym) # it's instance method
          method = obj.instance_method(sym)
        end
        next if method.nil?

        parameters = method.parameters.map{|k, v| v.to_s}
        method_sig = (parameters.empty?) ? sym.to_s : "#{sym.to_s}(#{parameters.join(', ')})" # construct the method signature
      
        unless method.source_location.nil? #unless we can't locate the source location
          @wiki.add_text(method_sig, :bold => true)
          @wiki.add_empty_line
          if method.source.strip.start_with?("define_method")
            # the mehtod is dynamically generated, try to get its description
            desc = full_methods_desc[sym.to_s]
            unless desc.nil?
              params = desc["params"]
              params.each do |params_set|
                params_str = "params(" + params_set.map{|k, v| "#{k}: #{v}"}.join(", ") + ")"
                @wiki.add_text(params_str)
                @wiki.add_empty_line
              end
            
              result = desc["result"]
              unless result.nil?
                result_str = "result(" + result.map{|k, v| "#{k}: #{v}"}.join(", ") + ")"
                @wiki.add_text(result_str)
                @wiki.add_empty_line
              end
            end
          end
          # here is the comment of method
          @wiki.add_text(method.comment, :italic => true) unless (method.comment.nil? || method.comment.length < 5)
          @wiki.add_codes_block(method.source)
        end
      rescue => e
        puts "Error parsing method '#{sym.to_s}' of #{obj.name}. Due to #{e.message}"
        puts method.source_location.inspect
      end
    }
  end
  
  # convert constants to wiki content
  def constants_to_wiki(constants)
    return if constants.empty?
    @wiki.add_subhead("Constants")
    @wiki.add_empty_line
    constants.each do |syb|
      @wiki.add_text(syb.to_s, :bold => true)
      @wiki.add_empty_line
    end
  end
  
  # convert variables to wiki content
  def variables_to_wiki(variables, type_str)
    return if variables.empty?
    @wiki.add_subhead(type_str)
    @wiki.add_empty_line
    variables.each do |syb|
      @wiki.add_text(syb.to_s, :bold => true)
      @wiki.add_empty_line
    end
  end
  
  def scan(obj)
    return if @scanned_objects.include? obj
    @scanned_objects << obj
    
    p "Scan #{obj.class} #{obj.to_s}"
    if obj.is_a? Class
      scan_class(obj)
    elsif obj.is_a? Module
      scan_module(obj)
    elsif obj.is_a? Object
      scan_object(obj)
    else
      raise "What? No such type!"
    end
    
    if obj.respond_to? :constants
      # scan the sub modules/classes contained within current obj
      obj.constants.select {|c| Class === obj.const_get(c)}.each do |c|
        constant = obj.const_get(c.to_s)
        scan constant
      end
    end
  end
  
  def scan_module(mod)
    raise "#{mod.inspect} is not a Moudle" unless mod.is_a? Module
    @wiki.add_head("#{mod.name} <Module> ")
    constants_to_wiki(mod.constants- Module.constants)
    @wiki.add_empty_line
    methods_to_wiki_from_object(mod.public_methods(false) - Object.public_methods, mod, PUBLIC_METHODS)
  end
  
  def scan_object(obj)
    @wiki.add_head("#{obj.class.name} <Class>")
    variables_to_wiki(obj.instance_variables, INSTANCE_VARIABLES)
    @wiki.add_empty_line
    methods_to_wiki_from_object(obj.class.public_methods(false) - Class.public_methods, obj.class, PUBLIC_CLASS_METHODS)
    @wiki.add_empty_line
    methods_to_wiki_from_object(obj.public_methods(false).reject{|v| v.to_s.include?('=')} - Object.new.public_methods - obj.instance_variables.map{|v| v.to_s.gsub('@', '').to_sym}, obj, PUBLIC_INSTANCE_METHODS)
  end
  
  def scan_class(klass)
    raise "#{klass.inspect} is not a Class" unless klass.is_a? Class
    @wiki.add_head("#{klass.name} <Class>")
    variables = klass.instance_variables.map{|v| v.to_s.gsub('@', '').to_sym}
    variables_to_wiki(variables, CLASS_VARIABLES)
    methods_to_wiki_from_object(klass.public_methods(false) - Class.public_methods, klass, PUBLIC_CLASS_METHODS)
    @wiki.add_empty_line
    instance_methods = (klass.instance_methods(false) - Object.instance_methods).reject{|m| m.to_s.start_with?('_')}
    methods_to_wiki_from_object(instance_methods, klass, PUBLIC_INSTANCE_METHODS)
    @wiki.add_empty_line
  end

  def close
    @wiki.close
  end
end