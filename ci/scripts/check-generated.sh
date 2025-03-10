#!/bin/bash
# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Returns 0 if there are no changes or untracked files, 1 otherwise.
# Show the diff on STDOUT if there's deviation.
is_clean() {
    local output
    output="$(git status --porcelain)" || return 1
    test -z "$output" && return 0
    echo Diff between the regenerated content and the content in this PR/the repository:
    git diff
    return 1
}

# Clean up the repo so that we can check further auto-generated stuff
destructive_cleanup() {
    git clean -fxd >/dev/null
    git reset --hard >/dev/null
}

# Run a command and then check the tree is still clean. Print a message if not.
gen_and_check_clean() {
    thing="$1"
    shift
    "$@" || {
        echo "::error::Failed to auto-generate ${thing}. (command: '$*')"
        echo
        destructive_cleanup
        return 1
    }

    is_clean || {
        echo "::error::Auto-generated ${thing} not up-to-date. Regenerate with '$*'."
        echo
        destructive_cleanup
        return 1
    }
}

# A specialized version of gen_and_check_clean for targets of the Makefile in hw
gen_hw_and_check_clean() {
    thing=$1; shift
    gen_and_check_clean "$thing" make -k -C hw "$*"
}

# Check generated files are up to date

bad=0

# Although this is a CI script, users might be tempted to run it locally.
# Protect their uncommitted changes before any calls to `destructive_cleanup`.
if [ "${OT_DESTRUCTIVE}" != "1" ]; then
    cat >&2 <<EOM
Aborted $0 because OT_DESTRUCTIVE != 1.

Setting OT_DESTRUCTIVE=1 will enable this script to delete uncommitted changes
from the working tree.

Never set OT_DESTRUCTIVE=1 automatically, except to define the CI environment.
The intent is to protect users from losing uncommitted changes, so it should be
the user's responsibility to set it.
EOM
    exit 1
fi
destructive_cleanup

gen_hw_and_check_clean "Register headers" regs             || bad=1
gen_hw_and_check_clean "LC state"         lc-state-enc     || bad=1

# This runs both top and cmdgen targets together since for ipgen
# ips the top target will not run cmdgen on generated md files,
# causing this check to fail.
gen_hw_and_check_clean "top and cmdgen"   top_and_cmdgen   || bad=1

gen_and_check_clean \
    "secded primitive code" \
    util/design/secded_gen.py --no_fpv || bad=1

gen_and_check_clean "MUBI package" util/design/gen-mubi.py || bad=1

gen_and_check_clean "HW block summary" util/gen_doc_hw_summary_table.py || bad=1

exit $bad
