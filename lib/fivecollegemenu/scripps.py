#!/usr/bin/env python
# coding=utf-8

import lxml.etree
import lxml.html
import re
import requests

URL = "http://www.scrippscollege.edu/students/dining-services/"

def date_regex(search_date):
	long_month = search_date.strftime("%b")
	short_month = search_date.strftime("%B")
	day = search_date.day

	return "((%s)|(%s))\s*%i" % (long_month, short_month, day)

def malott(search_date):
	html = requests.get(URL).text
	doc = lxml.html.fromstring(html)
	content = doc.xpath("//*[@id='content']")[0]

	h3s = content.xpath(".//h3")
	dates = filter(lambda _:
		re.search(date_regex(search_date), _.text_content()), h3s)

	for d in dates:
		mealname =  d.getnext().xpath(".//a")[0].text_content().strip()

import datetime

malott(datetime.date.today())

'''

class ScrippsParser < Parser
	def self.date_regex
		long_month = RIGHT_NOW.strftime("%b")
		short_month = RIGHT_NOW.strftime("%B")
		
		/(#{long_month})|(#{short_month})\s*#{RIGHT_NOW.mday}/
	end
	def self.parse(html)
		doc = Hpricot(html)
		
		content = doc/"#content"
		
		dates = (content/:h3).find_all do |h3|
			h3.to_plain_text =~ self.date_regex
		end
		
		if dates.empty?
			return {
				"Scripps" => Problem("No current menu available.")
			}
		end
		
		menu = {}
		
		dates.each do |h3|
			mealinfo = h3.next_sibling
			raise NotParagraphElement if not mealinfo.name =~ /p/i
			mealname = mealinfo.at(:a).inner_html.downcase.strip
			
			menuinfo = mealinfo.next_sibling
			raise NotListElement if not menuinfo.name =~ /ul/i
			
			meal = []
			
			groupname = ""
			items = []
			
			add_group = lambda do
				meal << {
					"header" => groupname,
					"items" => items
				}
				groupname = ""
				items = []
			end
			
			(menuinfo/:li).each do |li|
				if li.to_plain_text =~ /-/
					add_group.call
					groupname, itemname = li.to_plain_text.split("-", 2)
				else
					itemname = li.to_plain_text
				end
				items << itemname
			end
			add_group.call
			
			menu[mealname] = meal
		end
		
		return {
			"Scripps" => menu
		}
	end
end

'''