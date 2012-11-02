require 'rubygems'

require 'fileutils'
require 'json'

class DataCache < Hash
	def initialize (filename)
		super()
		@filename = filename
	end
	
	def add (data)
		# data is in the form of
		# {
		#   "Frank => {
		#     :breakfast => [<Group>,...]
		#   }
		# }
		
		self.merge!(data) { |key, old, new| old.merge new }
	end
	
	def load
		if File.exists? @filename
			self.merge! unserialize File.read @filename
		end
		if not self[:_date] == RIGHT_NOW.day
				self.clear
		end
	end
	
	def [](key)
		if include? key
			super(key)
		end
	end
	
	def save
		self[:_date] = RIGHT_NOW.day
		
		uid = Time.now.strftime '%s'
		unique_file = "#@filename-#{uid}"
		
		# puts "-> #{unique_file}"
		File.open(unique_file, 'w') { |f| f.write serialize }
		FileUtils.cp unique_file, @filename
	end
	
	protected
	
	def serialize
		raise NotImplementedError
	end
	
	def unserialize (data)
		raise NotImplementedError
	end
end

class JSONDataCache < DataCache
	protected
	
	def serialize
		JSON.pretty_generate self
	end
	def unserialize data
		JSON.parse data
	end
end