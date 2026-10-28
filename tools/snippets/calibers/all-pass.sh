#!/usr/bin/env bash
# Runs each test command given and fails if any exits non-zero or prints a FAIL line; prints each
# command's last summary line. Some older drivers (slice/uncommon.sh) exit 0 on FAIL.
#   tools/snippets/calibers/all-pass.sh "tools/snippets/calibers/check.sh calibers/records.lua" ...
cd "$(dirname "$0")/../../.."
status=0
for c in "$@"; do
  out="$(bash -c "$c" 2>&1)"; rc=$?
  fails=$(grep -c '^FAIL' <<<"$out"); passes=$(grep -c '^PASS' <<<"$out")
  echo "$c: $passes pass, $fails fail (exit $rc)"
  grep '^FAIL' <<<"$out" | head -5
  (( rc != 0 || fails > 0 || passes == 0 )) && status=1
done
exit $status
