all: static/js/site.js static/css/site.css 

static/css/site.css: lib/styl/*.styl
	node_modules/.bin/stylus --compress --use nib --include lib/styl < lib/styl/main.styl > static/css/site.css

static/js/site.js: lib/coffee/*.coffee
	node_modules/.bin/coffee -cj static/js/site.js \
		lib/coffee/util.coffee \
		lib/coffee/theory.coffee \
		lib/coffee/instrument.coffee \
		lib/coffee/main.coffee

uglify: node_modules/uglify-js/bin/uglifyjs static/js/site.js
	 node_modules/uglify-js/bin/uglifyjs static/js/site.js \
		--mangle --compress \
	 	--output static/js/site.js

clean:
	rm -f static/js/site.js
	rm -f static/css/site.css