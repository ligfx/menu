require 'rubygems'
require 'hpricot'

class Time
	def weekend?
		return (self.wday == 0 or self.wday == 6) # Sunday or Saturday
	end
	
	def weekday?
		return !weekend?
	end
end

class Fixnum
	def days
		return self * 24.hours
	end
	def hours
		return self * 60 * 60
	end
end

def number_to_ordinal(num)
  num = num.to_i
  if (10...20)===num
    "#{num}th"
  else
    g = %w{ th st nd rd th th th th th th }
    a = num.to_s
    c=a[-1..-1].to_i
    a + g[c]
  end
end

def Group (header="", items=[])
	{ "header" => header, "items" => items }
end
def Message (message)
	return [Group("", [message])]
end

def Problem (message)
	{
		:breakfast => Message(message),
		:lunch => Message(message),
		:dinner => Message(message)
	}
end


RIGHT_NOW = Time.now + 4.hours

class Parser
  class <<self; attr_accessor :after; end
  
	def self.all_subclasses
		ObjectSpace.each_object(Class).select { |klass| klass < self }.each { |klass| yield klass }
	end
	def self.parse (html)
		raise NotImplementedError
  end
end

Dir["parser/*.rb"].each do |parser|
	require parser
end
