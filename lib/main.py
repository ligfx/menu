#!/usr/bin/env python
# coding=utf-8

import datetime
import fivecollegemenu.pomona
import pystache

# cache directory?
# current day?
# parsers?
# template?

# TODO: Should be from env
cache_dir = "../cache"

current_day = datetime.datetime.today().date()

def fix_groups_structure(groups):
	return map(
		lambda (group_name, desc): {
		'name': group_name,
		'desc': desc},
	groups)

def fix_meals_structure(meals):
	return map(
		lambda (meal_name, groups): {
		'name': meal_name,
		'groups': fix_groups_structure(groups)},
	meals)

def pretty_date(date):
	return "%s, %i %s" % (date.strftime("%A"), date.day, date.strftime("%B"))

frary = fivecollegemenu.pomona.frary(current_day)
frary = fix_meals_structure(frary)

with open('templates/main.css') as f:
	css = f.read()

with open('templates/dining.html.mustache') as f:
	html_template = f.read()

print pystache.render(html_template, {
	'css': css,
	'today': pretty_date(current_day),
	'dining_halls': [
		{'name': 'Frary',
		 'meals': frary}
	]
	})