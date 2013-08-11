THIS	:= $(dir $(lastword $(MAKEFILE_LIST)))

# All content files.
CONTENT	:= $(shell find content -type f)
DIRS	:= $(patsubst content%,home%,$(shell find content -type d))
ifneq ($(wildcard external),)
DIRS	+= $(patsubst external%,home%,$(shell find external -type d))
endif
# POD files.
PODS	:= $(filter %.pod,$(CONTENT))
PODS	+= $(filter %.pod,$(EXTERNAL))
# HTML outputs.
HTML	:= $(PODS:.pod=.html)
HTML	:= $(patsubst content%,home%,$(HTML))
HTML	:= $(patsubst external%,home%,$(HTML))
# Additional non-preprocessed content.
DATA	:= $(patsubst content%,home%,$(filter-out %.pod,$(CONTENT)))
DATA	+= $(patsubst external%,home%,$(filter-out %.pod,$(EXTERNAL)))

# Generator script and its dependencies.
DEPEND	:= $(THIS)generate $(shell find $(THIS)lib -type f)

build: $(THIS)generate $(PODS) $(DATA) dirs
	$< $(filter %.pod,$(PODS))
	find home -type f -exec chmod 0644 {} ';'
	find home -type d -exec chmod 0755 {} ';'

dirs: clean
	mkdir -p $(DIRS)
	cp -a $(THIS)content/* home/

home/%: content/% dirs
	cp $< $@

home/%: external/% dirs
	cp $< $@

clean:
	rm -rf home
