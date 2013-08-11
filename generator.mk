THIS	:= $(dir $(lastword $(MAKEFILE_LIST)))

# All content files.
INPUTS	:= $(shell find content -type f)
DIRS	:= $(patsubst content%,home%,$(shell find content -type d))
# POD files.
PODS	:= $(filter %.pod,$(INPUTS))
# HTML outputs.
HTML	:= $(patsubst content%,home%,$(PODS:.pod=.html))
# Additional non-preprocessed content.
DATA	:= $(patsubst content%,home%,$(filter-out %.pod,$(INPUTS)))

# Generator script and its dependencies.
DEPEND	:= $(THIS)/generate $(shell find $(THIS)/lib -type f)

build: $(THIS)/generate $(PODS) $(DATA)
	$< $(filter %.pod,$(PODS))
	find home -type f -exec chmod 0644 {} ';'
	find home -type d -exec chmod 0755 {} ';'

dirs: clean
	mkdir -p $(DIRS)

home/%: content/% dirs
	cp $< $@

clean:
	rm -rf home
