class BonAppetitParser < Parser
	def self.date_regex
		short_month = RIGHT_NOW.strftime("%b")
		long_month = RIGHT_NOW.strftime("%B")
		day = RIGHT_NOW.strftime("%d").sub(/^0/,'')
		/((#{short_month})|(#{long_month}))\s*0?#{day}/i
	end
	def self.parse_group(rows)
		first = rows.shift
		raise Error if not (first/:td).size == 3
		
		header = (first/:td).first
		groupname = header.to_plain_text.strip
		length = header["rowspan"].to_i
		
		items = []
		
		items << (first/:td)[1].to_plain_text.gsub(/\[img:.*?\]/, '')
		
		(length - 1).times do
			row = rows.shift
			items << (row/:td).first.to_plain_text.gsub(/\[img:.*?\]/, '')
		end
		
		{
			"header" => groupname,
			"items" => items
		}
	end
	def self.parse_meal(rows)
		first = rows.shift
		raise Error if not (first/:td).size == 1
		
		name = first.to_plain_text.strip.downcase
		
		groups = []
		
		while rows.any? and (rows.first/:td).size != 1
			groups << parse_group(rows)
		end
		
		{ name => groups }
	end
	def self.parse(html)
		doc = Hpricot(html)
		
		menus = doc/"#menu-items"
		date = (menus/".date").find { |d| d.to_plain_text =~ self.date_regex }
		if not date
			return Problem("No current menu available.")
		end
		table = date.next_sibling
		if not table.name =~ /table/i
			return Problem("No current menu available.")
		end
		
		meals = {}
		rows = (table/:tr)
		while rows.any?
			begin
				meals.merge! parse_meal(rows)
			rescue => e
				return Problem("Please use the official site, linked above")
			end
		end
		
		return meals
	end
end

class CollinsParser < BonAppetitParser
	def self.parse(html)
		meals = super
		meals["snack"] = meals["grab 'n' go"]
		{
			"Collins" => meals
		}
	end
end

class PitzerParser < BonAppetitParser
	def self.parse(html)
		{
			"Pitzer" => super
		}
	end
end

__END__
CollinsSnackParser.after_parse do |menu|
  days_snack_is_closed = [
    5, # Friday
    6, # Saturday
    0 # Sunday
  ]
  if days_snack_is_closed.include? RIGHT_NOW.wday
    menu["Collins"][:snack] = Message("Snack is open Monday, Tuesday, Wednesday, and Thursday")
  end
end