PHONY: deps
deps:
	npm install

PHONY: toc
toc: deps
	npx markdown-toc -i style-guide.md --bullets="*" --maxdepth=3

markdownlint: deps
	npx markdownlint-cli2 style-guide.md --config=.markdownlint.yaml
