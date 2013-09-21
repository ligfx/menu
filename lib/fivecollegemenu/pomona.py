#!/usr/bin/env python
# coding=utf-8

from codecs import open
from collections import namedtuple, OrderedDict
from datetime import date
from datetime import timedelta
from itertools import groupby
import json
import lxml.html
import os
import re
import requests
from urllib import quote

def I(x): return x

def download((url, after)):
	return after(download_helper_maybe_cache(url))

def download_helper_maybe_cache(url):
	# if debugging, comment out this line to go faster!
	return requests.get(url).text

	cachename = "{0}.cache".format(quote(url, safe=''))
	try:
		with open(cachename) as f:
			return f.read()
	except:
		data = requests.get(url).text
		with open(cachename, "w", encoding="utf-8") as f:
			f.write(data)
		return data

def find_spreadsheet_id(data):
	doc = lxml.html.fromstring(data)
	spreadsheet_id = doc.xpath('//*[@data-google-spreadsheet-id]')
	assert len(spreadsheet_id) == 1
	return spreadsheet_id[0].get('data-google-spreadsheet-id')

def parse_hyphenated_date(s):
	month, day, year = map(int, s.split("-"))
	return date(2000 + year, month, day)

class GoogleWorksheet:
	def __init__(self, w):
		self.w = w
	def __repr__(self):
		return repr(self.w)
	def __getitem__(self, key):
		return self.w[key]
	def date(self):
		return parse_hyphenated_date(self.w['title']['$t'])

def get_worksheets_for_key(key):
	def after(resp):
		worksheets_json = json.loads(resp)
		worksheets = worksheets_json['feed']['entry']
		return map(GoogleWorksheet, worksheets)

	worksheets_url_template = "https://spreadsheets.google.com/feeds/worksheets/{key}/public/basic?alt=json"	
	worksheets_url = worksheets_url_template.format(key=key)
	
	return (worksheets_url, after)

def get_cells_feed(worksheet):
	def after(resp):
		cells = json.loads(resp)['feed']['entry']
		return map(GoogleCell, cells)

	links = worksheet['link']
	rel = "http://schemas.google.com/spreadsheets/2006#cellsfeed"
	cells_links = filter(lambda l: l['rel'] == rel, links)
	assert len(cells_links) == 1
	cells_url = cells_links[0]['href'] + "?alt=json"

	return (cells_url, after)

def most_recent_monday(d):
	return d - timedelta(days=d.weekday())

class NotFoundException(Exception): pass

def find(cond, seq):
	try:
		return next(iter(filter(cond, seq)))
	except StopIteration:
		raise NotFoundException(cond, seq)

class GoogleCell:
	def __init__(self, c):
		position = c['title']['$t']
		self.column = str(position[0])
		self.row = int(position[1:])
		value = c['content']['$t']
		value = re.sub(u'[\xa0\s]+', ' ', value)
		self.value = value.strip().encode('utf-8')
	def __repr__(self):
		return "(%s, %i, %s)" % (self.column, self.row, self.value)

def parse_cells_with_start_date(cells, start_date):
	# First row is header "Frary dates"
	# Then groups of:
	#   header: day, station, meal names
	#   day of week in first row, first column
	#   station names in second column
	#   meals in other columns

	current_date = start_date
	header = cells.pop(0).value

	while len(cells) > 0:
		row = cells[0].row
		assert "Day" in cells.pop(0).value
		if cells[0].value == "Station":
			cells.pop(0)
		meal_names = {}
		meals = OrderedDict()
		while cells[0].row == row:
			meal = cells.pop(0)
			meal_names[meal.column] = meal.value
			meals[meal.value] = []

		day_of_week = cells.pop(0).value

		while len(cells) > 0 and cells[0].column != "A":
			row = cells[0].row
			station_name = cells.pop(0).value

			while len(cells) > 0 and cells[0].row == row:
				m = cells.pop(0)
				meal_name = meal_names.get(m.column, "NOMEAL")
				meals[meal_name] = meals.get(meal_name, [])
				meals[meal_name].append((station_name, m.value))

		yield (current_date, [(k, v) for k, v in meals.items()])
		current_date = current_date + timedelta(days=1)

def cell_rows(cells):
	for k, g in groupby(cells, lambda c: c.row):
		yield list(g)


def parse_oldenborg_cells_with_start_date(cells, start_date):
	# First row is header "'Oldenborg'"
	# Second row is "'Dish' *dates"
	# All other rows: first cell (A) is group name, next cells are
	# values for each day.

	current_date = start_date
	header = cells.pop(0).value
	assert "Oldenborg" in header

	rows = cell_rows(cells)
	assert "Dish" in next(rows)[0].value

	dates = []

	for i in range(5):
		dates.append((
			current_date + timedelta(days=i),
			((u'Lunch', []),)
		))

	for r in rows:
		group_name, descs = r[0], r[1:]
		for i, d in enumerate(descs):
			dates[i][1][0][1].append((group_name.value, d.value))
	
	return dates

def print_menu(menu):
	for (date, meals) in menu:
		print(date)
		for (mealname, groups) in meals:
			print("  " + mealname)
			for (groupname, desc) in groups:
				print("    " + "= %s" % groupname)
				print("    " + desc)

def get_menu(search_date, url):
	html = download((url, I))
	spreadsheet_key = find_spreadsheet_id(html)
	worksheets = download(get_worksheets_for_key(spreadsheet_key))
	worksheet = find(lambda _: _.date() == most_recent_monday(search_date), worksheets)
	start_date = most_recent_monday(search_date)
	cells = download(get_cells_feed(worksheet))
	dates = parse_cells_with_start_date(cells, start_date)
	return filter(lambda (day, _): day == search_date, dates)[0][1]

def get_pomona(slug, search_date):
	return get_menu(search_date, "http://www.pomona.edu/administration/dining/menus/%s.aspx" % slug)

def frary(*args): return get_pomona("frary", *args)
def frank(*args): return get_pomona("frank", *args)
def oldenborg(search_date):
	html = download(("http://www.pomona.edu/administration/dining/menus/oldenborg.aspx", I))
	spreadsheet_key = find_spreadsheet_id(html)
	worksheets = download(get_worksheets_for_key(spreadsheet_key))
	worksheet = find(lambda _: _.date() == most_recent_monday(search_date), worksheets)
	start_date = most_recent_monday(search_date)
	cells = download(get_cells_feed(worksheet))
	dates = parse_oldenborg_cells_with_start_date(cells, start_date)
	return filter(lambda (day, _): day == search_date, dates)[0][1]
