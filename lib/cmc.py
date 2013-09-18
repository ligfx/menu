#!/usr/bin/env python
# coding=utf-8

import dateutil.parser
from lxml import etree
import json
import re
import requests

def each_slice(seq, n):
	return zip(*[iter(seq)]*n)

def parse_rss():
	resp = requests.get("http://legacy.cafebonappetit.com/rss/menu/50")
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

def cmc(search_date):
	menu = parse_rss()
	return filter(lambda (day, meals): day == search_date, menu)[0][1]