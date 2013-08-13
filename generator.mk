THIS	:= $(dir $(lastword $(MAKEFILE_LIST)))

# All content files.
CONTENT	= $(shell find external -not -type d)
DIRS	= $(patsubst external%,home%,$(shell find external -type d))
# POD files.
PODS	= $(filter %.pod,$(CONTENT)) $(filter %.shtml,$(CONTENT))
# HTML outputs.
HTML	= $(patsubst external%,home%,$(addsuffix .html,$(basename $(PODS))))
# Additional non-preprocessed content.
DATA	= $(patsubst external%,home%,$(filter-out %.shtml,$(filter-out %.pod,$(CONTENT))))

# Generator script and its dependencies.
DEPEND	:= $(THIS)generate $(shell find $(THIS)lib -type f) config.pm

home/%.html: external/%.pod $(DEPEND) $(DIRS)
	$(THIS)generate $<

home/%.html: external/%.shtml $(DEPEND) $(DIRS)
	$(THIS)generate $<

home/%: external/% $(DIRS)
	cp $< $@

build: $(HTML) $(DATA) $(DIRS)
	find home -type f -exec chmod 0644 {} ';'
	find home -type d -exec chmod 0755 {} ';'

$(DIRS):
	mkdir -p $@

clean:
	rm -rf home external

define copycommon

external.stamp: $(patsubst $1%,external%,$2)
$(patsubst $1%,external%,$2): $2
	@mkdir -p $$(@D)
	ln -sf $$(realpath $$<) $$@

endef

$(eval $(foreach D,$(THIS)content content,$(foreach S,$(shell find $D -not -type d),$(call copycommon,$D,$S))))

-include external.stamp
