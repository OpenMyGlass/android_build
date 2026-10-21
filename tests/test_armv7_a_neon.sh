#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# OpenMyGlass: evaluate core/combo/arch/arm/armv7-a-neon.mk for each CPU variant and check the
# flags it emits. Run from the repository root: sh tests/test_armv7_a_neon.sh
set -eu
mk=core/combo/arch/arm/armv7-a-neon.mk
fail=0
flags() {
    printf 'include %s\nall:\n\t@echo "$(strip $(arch_variant_cflags)) | $(strip $(arch_variant_ldflags))"\n' "$mk" \
        | make -s -f - TARGET_CPU_VARIANT="$1"
}
expect() {
    got=$(flags "$1")
    if [ "$got" = "$2" ]; then
        echo "ok   $1: $got"
    else
        echo "FAIL $1: got '$got', want '$2'"
        fail=1
    fi
}
expect cortex-a9  "-mcpu=cortex-a9 -mfloat-abi=softfp -mfpu=neon | -Wl,--no-fix-cortex-a8"
expect cortex-a8  "-mcpu=cortex-a8 -mfloat-abi=softfp -mfpu=neon | -Wl,--fix-cortex-a8"
expect cortex-a15 "-mcpu=cortex-a15 -mfloat-abi=softfp -mfpu=neon | -Wl,--fix-cortex-a8"
expect cortex-a7  "-mcpu=cortex-a7 -mfloat-abi=softfp -mfpu=neon | -Wl,--fix-cortex-a8"
expect ""         "-march=armv7-a -mfloat-abi=softfp -mfpu=neon | -Wl,--fix-cortex-a8"
exit $fail
