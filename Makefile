all: reset-elm.js zxcvbn.js

reset-elm.js: Reset.elm PasswordField.elm Lib.elm
	elm make Reset.elm --output $@

zxcvbn.js:
	curl -O https://raw.githubusercontent.com/dropbox/zxcvbn/master/dist/zxcvbn.js
