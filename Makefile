all: reset-elm.js zxcvbn.js

reset-elm.js: Reset.elm PasswordField.elm
	elm make Reset.elm --output $@

zxcvbn.js:
	curl -O https://raw.githubusercontent.com/dropbox/zxcvbn/master/dist/zxcvbn.js

min: reset-min.html reset-elm.min.js

reset-min.html: reset.html
	perl -pe 's/reset-elm\.js/reset-elm.min.js/' $< > $@

UGLIFYOPTS = --comments --compress --mangle

reset-elm.min.js: reset-elm.js
	uglifyjs $< --output $@ $(UGLIFYOPTS)


clean:
	-rm reset-elm.js reset-elm.min.js reset-min.html
	-rm -r elm-stuff
