$:.unshift File.dirname __FILE__

require 'data_cache'
require 'html_cache'
require 'parser'

require 'active_support/core_ext/hash/keys'
require 'erubis'
require 'yaml'

#Encoding.default_internal = 'UTF-8'

@info = YAML::load_file "info.yaml"

uris = {
	FrankParser => @info["Frank"]["uri"],
	FraryParser => @info["Frary"]["uri"],
	OldenborgParser => @info["Oldenborg"]["uri"],

	CollinsParser => @info["Collins"]["uri"],
	PitzerParser => @info["Pitzer"]["uri"],
	
	ScrippsParser => @info["Scripps"]["uri"]
}

cachedir = "cache"
if ENV["LAZY"]
	@cache = LazyHTMLCache.new cachedir
else
	@cache = HTMLCache.new cachedir
end
if not ARGV.empty?
	parser = eval "::#{ARGV.first}"
	html = @cache.get uris[parser], parser.name.chomp("Parser")
	pp parser.parse html
	exit(0)
end

begin
	uri_pattern = @info["Mudd"]["uri_pattern"]
	uris[MuddParser] = @info["Mudd"]["uri"] = (1..10).
	map do |i|
		uri = uri_pattern.gsub("%i", i.to_s)
	end.find do |uri|
		$stderr.puts uri
		html = @cache.get uri, ("Mudd#{File.basename(uri)}").chomp(File.extname(uri))
		MuddParser.match html
	end
end

@data = JSONDataCache.new "cache/data.json"
@data.load

uris.each do |parser, uri|
	html = @cache.get uri, parser.name.chomp("Parser")
	begin
		@data.add parser.parse(html) unless html.empty?
	rescue => e
		$stderr.puts "#{parser} failed!"
		$stderr.puts e
		$stderr.puts e.backtrace
	end
end
@data.save

class Source
	attr_reader :name
	
	def initialize (name, info, data)
		@name = name
		@info = info[name]
		
		if data[name]
			@menus = data[name].symbolize_keys
		else
			@menus = {
				:breakfast => [{"header"=>"","items"=>["Please use the the official site, linked above."] }],
				:lunch => [{"header"=>"","items"=>["Please use the the official site, linked above."] }],
				:dinner => [{"header"=>"","items"=>["Please use the the official site, linked above."] }]
			}
		end
	end
	
	def uri (meal)
		@info["uri"]
	end
	
	def hours (meal)
		@info["hours"].symbolize_keys.tap do |h|
			if RIGHT_NOW.weekend? and h.include? :dinner_weekend
				h[:dinner] = h[:dinner_weekend]
			end
		end[meal.to_sym]
	end
	
	def menu (meal) # : [Group]
		meal = "lunch" if meal == "brunch"
		if @menus[meal.to_sym]
			@menus[meal.to_sym].map { |group_data| Group.new group_data }
		else
			[Group.new({"header"=>"","items"=>["Please use the link above for the dining menu."]})]
		end
	end
end

class Group
	attr_reader :header
	attr_reader :items
	
	def initialize (data)
		@header = data["header"]
		@items = data["items"]
	end
end

sources = "Frank", "Frary", "Collins", "Scripps", "Pitzer", "Mudd"
sources.map! { |name| Source.new name, @info, @data }

if RIGHT_NOW.weekend?
	meals = "brunch", "dinner"
else
	meals = "breakfast", "lunch", "dinner"
end

def partial (template, opts = {})
	input = File.read "_#{template}.erb"
	eruby = Erubis::Eruby.new input
	eruby.evaluate opts
end

input = File.read "dining.html.erb"
eruby = Erubis::Eruby.new input
puts eruby.evaluate :info => @info, :sources => sources, :meals => meals, :oldenborg => Source.new("Oldenborg", @info, @data)
