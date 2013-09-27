ifeq ($(TARGET),)
$(error Define TARGET, first)
endif

THIS	:= $(dir $(lastword $(MAKEFILE_LIST)))

# Generator script and its dependencies.
DEPEND	:= $(THIS)generator $(shell find $(THIS)lib -type f) config.pm

# All html pages.
HTML	= $(shell find $(TARGET) -name "*.html" -or -name "*.xhtml")

build: $(DEPEND)
	$< $(TARGET) $(FLAGS)
	$(THIS)mkfavicon
	find $(TARGET) -type f -exec chmod 0644 {} ';'
	find $(TARGET) -type d -exec chmod 0755 {} ';'
	$(MAKE) post-build

$(TARGET)/%.txt: staging/%.pod
	pod2text $< $@

post-build:
