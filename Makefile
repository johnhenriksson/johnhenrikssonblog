# Please change the theme version to the latest release version.
THEME_VERSION := v0.26.1
THEME := hugo-geekblog
BASEDIR := ./
THEMEDIR := $(BASEDIR)/themes

.PHONY: doc
doc: doc-assets doc-build

.PHONY: doc-assets
doc-assets:
	mkdir -p $(THEMEDIR)/$(THEME)/ ; \
	curl -sSL "https://github.com/thegeeklab/$(THEME)/releases/download/${THEME_VERSION}/$(THEME).tar.gz" | tar -xz -C $(THEMEDIR)/$(THEME)/ --strip-components=1

.PHONY: doc-build
doc-build:
	cd $(BASEDIR); hugo

.PHONY: clean
clean:
	rm -rf $(THEMEDIR) && \
	rm -rf $(BASEDIR)/public