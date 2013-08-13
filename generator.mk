THIS	:= $(dir $(lastword $(MAKEFILE_LIST)))

# Generator script and its dependencies.
DEPEND	:= $(THIS)generator $(shell find $(THIS)lib -type f) config.pm

build: $(DEPEND)
	$< $(FLAGS)
	find home -type f -exec chmod 0644 {} ';'
	find home -type d -exec chmod 0755 {} ';'
