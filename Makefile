###############################################################################
#
# File: Makefile
#
# Copyright 2014 TiVo Inc. All Rights Reserved.
#
###############################################################################

ISM_DEPTH := ..
include $(ISM_DEPTH)/ismdefs

# We do not regenerate the run.n here as part of the build of OpenFL
# since it is such a simple wrapper around the lime haxelib.  Instead,
# we just use the checked in run.n file which should be extremely
# portable since it is neko byte code.
#
# To rebuild the run.n, be sure that you have some version of
# lime-tools in your haxelib path and build it the "OpenFL way" (cd
# script; p4 edit ../run.n; haxe build.hxml).


HAXELIB_NAME := openfl

# This is defined because this haxelib already has a haxelib.json file and
# doesn't need one to be generated
SUPPRESS_HAXELIB_JSON := 1

include $(ISMRULES)
