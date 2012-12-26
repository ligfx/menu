class PomonaParser < Parser
	def self.parse (html)
		main = Hpricot(html).at "div#main-content"
		
		table_caption = (main/".table-caption").find do |caption| 
			caption.to_plain_text =~ /#{RIGHT_NOW.strftime "%A"}/i
		end
		if not table_caption
			return Problem("The menu has not been updated yet. Try checking back later.")
		end
		
		menu = table_caption.next_sibling
		if not menu.classes.include? "menu"
			return Problem("An error occurred. Please use the official site, linked above.")
		end
	
		rows = (menu/:tr)
		
		meal_names = {}
		(rows[0]/:th).each do |cell|
			meal = cell['class'].strip.downcase
			name = (name = cell.at ".mealName") ? name.to_plain_text.strip : cell.to_plain_text.split("-")[1..-1]
			meal_names[meal] = name
		end
		
		groups = []
		rows[1..-1].each do |row|
			info = {}
			(row/:td).each do |cell|
				cell.classes.each do |klass|
					info[klass] = cell.to_plain_text.strip
				end
			end
			groups << info
		end
		
		meals = {}
		
		meal_names.each do |meal, meal_name|
			next if meal =~ /station/i
			info = []
			info << {
				"header" => "<span style=\"text-decoration: underline;\">#{meal_name}</span>",
				"items" => [],
			}
			groups.each do |group|
				info << {
					"header" => group["station"],
					"items" => [group[meal]],
				}
			end
			meal = "lunch" if meal =~ /brunch/i
			meals[meal] = info
		end
		
		return meals
	end
end

class FraryParser < PomonaParser
	def self.parse(html)
		return "Frary" => super
	end
end

class FrankParser < PomonaParser
	def self.parse(html)
		return "Frank" => super
	end
end
class OldenborgParser < PomonaParser
	def self.parse(html)
		return "Oldenborg" => super
	end
end