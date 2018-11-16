###############################################################################
#
# File: Makefile
#
# Copyright 2014 TiVo Inc. All Rights Reserved.
#
###############################################################################

ISM_DEPTH := ..
include $(ISM_DEPTH)/ismdefs

HAXELIB_NAME := openfl

# This is defined because this haxelib already has a haxelib.json file and
# doesn't need one to be generated
SUPPRESS_HAXELIB_JSON := 1

PRE_BOM_TARGETS += BuildRunScript

# Because the stock openfl .hxml files always write their output .n files into
# the current directory, and because of the way relative paths are used in
# its build scripts, deep staging is required
DEEP_STAGING_REQUIRED = 1

include $(ISMRULES)


.PHONY: BuildRunScript
BuildRunScript: $(HAXELIB_STAGED_DIR)/run.n
$(HAXELIB_STAGED_DIR)/run.n: $(STAGE_HAXELIB_TARGET) script/build.hxml
	@$(ECHO) -n "$(ISMCOLOR)$(ISM_NAME)$(UNCOLOR): "; \
	$(ECHO) "$(COLOR)Rebuilding OpenFL command for $(HAXE_HOST_SYSTEM)$(UNCOLOR)";
	$(Q) cd $(HAXELIB_STAGED_DIR)/script; \
	  $(HAXE) build.hxml
