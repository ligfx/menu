all: gen up

gen:
	bundle exec ruby controller.rb > out.html

up: cache/upload.stamp	

cache/upload.stamp: out.html
	test -s out.html && scp out.html nfs:/home/public/5cmenu/index.html && touch cache/upload.stamp
