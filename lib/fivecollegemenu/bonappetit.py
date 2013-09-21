#!/usr/bin/env python
# coding=utf-8

import dateutil.parser
from lxml import etree
import json
import re
import requests

def each_slice(seq, n):
	return zip(*[iter(seq)]*n)

def parse_rss(id):
	resp = requests.get("http://legacy.cafebonappetit.com/rss/menu/%s" % id)
	rss = etree.fromstring(resp.text.encode('utf-8'))

	for item in rss.xpath("*/item"):
		date = dateutil.parser.parse(item.xpath("title")[0].text).date()
		description = item.xpath("description")[0].text
		description = description.replace("&nbsp;", " ").replace("&#38;", "&")
		meals = []
		tokens = re.split("<h3>([^<]+)</h3>", description)
		assert tokens.pop(0) == ""
		for mealname, desc in zip(*[iter(tokens)]*2):
			desc = re.sub("\s+", " ", re.sub("<[^>]+>", "", desc)).strip()
			group_tokens = re.split("\s*\[([^\]]+)\]\s*", desc)
			group_tokens.pop(0)
			groups = []
			for groupname, desc in each_slice(group_tokens, 2):
				groups.append((groupname, desc))
			meals.append((mealname, groups))
		
		yield (date, meals)

def find_date(search_date, menu):
	return filter(lambda (day, meals): day == search_date, menu)[0][1]

def collins(search_date):
	return find_date(search_date, parse_rss("50"))

def mcconnell(search_date):
	return find_date(search_date, parse_rss("219"))