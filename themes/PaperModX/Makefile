run-default:
	cd exampleSite && hugo server -D --gc -p 13131 --config config.default.yml

run-profile-mode:
	cd exampleSite && hugo server -D --gc -p 13131 --config config.profileMode.yml

chroma-css:
	hugo gen chromastyles --style=monokai > assets/css/lib/chroma-dark.css
	hugo gen chromastyles --style=github-dark > assets/css/lib/chroma-light.css
