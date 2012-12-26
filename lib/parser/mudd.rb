class MuddParser < Parser
	def self.date_regex
		long_month = RIGHT_NOW.strftime("%B")
		short_month = RIGHT_NOW.strftime("%b")
		short_month = /Sept?/i if short_month == "Sep"
		day_number = RIGHT_NOW.strftime("%d").sub(/^0+/,'')
		/(#{long_month})|(#{short_month})\s*0*#{day_number}/iu
	end
	def self.match (html)
		html =~ date_regex
	end
	def self.parse (html)
		doc = Hpricot(html)
		
		table = doc.at "#table"
		unless doc.to_plain_text =~ date_regex
			return { "Mudd" => Problem("Mudd has not updated its menu yet. Try checking back later.") }
		end
		
		day = (RIGHT_NOW.wday + 3) % 7
		if day == 0
			day = (RIGHT_NOW.wday + 3) % 8
		end
		
		meals = {}
		
		meal = []
		mealname = nil
		group = nil
		(table/:tr).each do |row|
			if row.at "td.meal_row"
				if mealname
					meal << group
					raise UnknownMealError unless ["breakfast", "lunch", "dinner"].include? mealname
					meals[mealname.to_sym] = meal
				end
				
				meal = []
				mealname = (row/"td.meal_row")[1].to_plain_text.downcase
				mealname = "lunch" if mealname == "brunch"
				group = Group()
			end
			if (platform = row.at "td.platform_column")
				groupname = platform.to_plain_text.gsub(/\?/u,'').gsub(/\s+/u,' ').gsub(/\302\240/u, "").strip
				unless groupname.empty?
					meal << group
					group = Group groupname
				end
				
				item = (row/:td)[day].to_plain_text.gsub(/\?/u,'').gsub(/\s+/u,' ').gsub(/\302\240/u, "").strip
				group["items"] << item unless item.empty?
			end
		end
		meal << group
		raise DinnerIsNotLastMealError unless mealname == "dinner"
		meals[mealname.to_sym] = meal
		meals[:lunch] = meals[:breakfast] + meals [:lunch] if RIGHT_NOW.weekend?
		return { "Mudd" => meals }
	end
end
