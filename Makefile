PHONY: toc
toc:
	npm install # installs the markdown-toc at the expected version from package.json
	npx markdown-toc -i style-guide.md --bullets="*" --maxdepth=3
