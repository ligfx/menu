require 'fileutils'
require 'timeout'
require 'mechanize'

class HTMLCache

	def initialize (directory)
		@directory = directory
	end

	def get (uri, tag)
		download uri, tag

		cache_file = cache_file_name tag
		if File.exists? cache_file
			return File.read cache_file
		else
			return ""
		end
	end
	
	def download (uri, tag)
		begin
			new_html = nil
			$stderr.puts "<- #{tag}"
			agent = Mechanize.new
			Timeout.timeout(15) { new_html = agent.get(uri).body }
			
			uid = Time.now.strftime '%s'
			cache_file = cache_file_name tag
			new_cache_file = "#@directory/#{tag}.html-#{uid}"
			
			if File.exists?(cache_file) and File.read(cache_file) == new_html
				# do nothing
			else
				$stderr.puts "-> #{cache_file}"
				FileUtils.mkdir(@directory) unless File.exists?(@directory)
				File.open(new_cache_file, 'w') { |f| f.write new_html }
				FileUtils.cp new_cache_file, cache_file
			end
		rescue Timeout::Error => e
			$stderr.puts "!! #{tag}"
		rescue => e
			$stderr.puts e
			$stderr.puts "!! #{tag}"
		end
	end
	
	protected
	
	def cache_file_name (tag)
		"#@directory/#{tag}.html"
	end
end

class LazyHTMLCache < HTMLCache
	def download (uri, tag)
		super unless File.exists? cache_file_name(tag)
	end
end