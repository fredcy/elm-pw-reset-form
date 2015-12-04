all: reset-elm.js zxcvbn.js

reset-elm.js: Reset.elm PasswordField.elm
	elm make Reset.elm --output $@

zxcvbn.js:
	curl -O https://raw.githubusercontent.com/dropbox/zxcvbn/master/dist/zxcvbn.js

ugly: reset-ugly.html reset-elm-ugly.js

reset-ugly.html: reset.html
	perl -pe 's/reset-elm\.js/reset-elm-ugly\.js/' $< > $@

UGLIFYOPTS = --comments --compress --mangle

reset-elm-ugly.js: reset-elm.js
	uglifyjs $< --output $@ $(UGLIFYOPTS)


clean:
	-rm reset-elm.js reset-elm-ugly.js reset-ugly.html
	-rm -r elm-stuff
