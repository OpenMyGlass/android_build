#!/bin/sh
# shellcheck disable=SC2016  # make variables in single quotes, not shell ones
# SPDX-License-Identifier: Apache-2.0
# OpenMyGlass: core/binary.mk puts TARGET_SPECIFIC_HEADER_PATH in front of every module's
# include path (hardware/ti/omap4's BoardConfigCommon.mk sets it to domx/omx_core/inc, TI's
# OpenMAX headers). Evaluates the block from binary.mk on its own and checks the order.
# Run from the repository root: sh tests/test_header_path.sh
set -eu
mk=core/binary.mk
block=$(sed -n '/^## Allow a device.s own headers/,/^endif$/p' "$mk")
[ -n "$block" ] || { echo "FAIL: no TARGET_SPECIFIC_HEADER_PATH block in $mk"; exit 1; }
# The block must come before binary.mk adds the module's own directories.
first=$(grep -n 'TARGET_SPECIFIC_HEADER_PATH' "$mk" | head -n 1 | cut -d: -f1)
own=$(grep -n '^my_c_includes += \$(TOPDIR)\$(LOCAL_PATH)' "$mk" | head -n 1 | cut -d: -f1)
[ -n "$own" ] && [ "$first" -lt "$own" ] || { echo "FAIL: block is not before the module's own includes"; exit 1; }
run() {
    printf 'my_c_includes := a/include\n%s\nall:\n\t@echo "$(strip $(my_c_includes))"\n' "$block" \
        | make -s -f - TOPDIR= TARGET_SPECIFIC_HEADER_PATH="$1"
}
fail=0
expect() {
    got=$(run "$1")
    if [ "$got" = "$2" ]; then echo "ok   '$1': $got"; else echo "FAIL '$1': got '$got', want '$2'"; fail=1; fi
}
expect "hardware/ti/omap4/domx/omx_core/inc" "hardware/ti/omap4/domx/omx_core/inc a/include"
expect "" "a/include"
exit $fail
