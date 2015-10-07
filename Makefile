# Edit here - set path to you directory with config.json & fonts

glyphs:
	node_modules/.bin/fontello-cli install --config resources/fonts/config.json --font resources/fonts/ --css styles/fontello/
	grep "^\\.email-icon-" styles/fontello/email-icons.css \
	| perl -n -e 's/:before \{/:before \{ .email-icons; /;print' \
	> styles/fontello/email-icons.less

open-fontello:
	node_modules/.bin/fontello-cli open --config resources/fonts/config.json
