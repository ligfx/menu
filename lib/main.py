#!/usr/bin/env python
# coding=utf-8

from codecs import open
import datetime
import fivecollegemenu.pomona
import fivecollegemenu.bonappetit
import pystache
import sys

# cache directory?
# current day?
# parsers?
# template?

# TODO: Should be from env
cache_dir = "../cache"

today = datetime.datetime.today().date()

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

menus = (
	('Frank', fivecollegemenu.pomona.frank),
	('Frary', fivecollegemenu.pomona.frary),
	('Collins', fivecollegemenu.bonappetit.collins),
	('McConnell', fivecollegemenu.bonappetit.mcconnell),
	('Oldenborg', fivecollegemenu.pomona.oldenborg),
)

def log(s):
	sys.stderr.write("{0}\n".format(s))

def retrieve_menu((name, func)):
	log("Retrieving %s" % name)
	return (name, fix_meals_structure(func(today)))

def menu_as_dict((name, meals)):
	return {'name': name, 'meals': meals}

retrieved_menus = map(retrieve_menu, menus)
log(retrieved_menus)

with open('templates/main.css') as f:
	css = f.read().encode('utf-8')

with open('templates/dining.html.mustache') as f:
	html_template = f.read()

context = {
	'css': css,
	'today': pretty_date(today),
	'dining_halls': map(menu_as_dict, retrieved_menus)
	}
renderer = pystache.Renderer(string_encoding='utf-8', decode_errors="replace")
print(renderer.render(html_template, context).encode('utf-8'))