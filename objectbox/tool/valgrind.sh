#!/usr/bin/env bash
set -euo pipefail

# Note: when you see the process seemingly stuck after printing "All tests passed!", it's because dart2native produced
#       binaries will wait for any background isolates to finish before stopping the process.
#       For example, the following code has the issue: `HttpClient().get(...)`
#       while `final httpClient = HttpClient(); httpClient.get(...); httpClient.close(force: true);` works fine.

root=$(
  cd "$(dirname "$0")/.."
  pwd -P
)
echo "Package root dir: $root"

if [[ "$#" -gt "1" ]]; then
  echo "usage: $0 [test name]"
  echo "e.g. $0"
  echo "or   $0 query"
  exit 1
fi

testDir="${root}/build/test/valgrind"
rm -rf "${testDir}"
mkdir -pv "${testDir}"

function testWithValgrind() {
  echo "Running $1 with valgrind"
  testExe="${testDir}/${1%.*}"
  dart2native "${root}/test/${1}" --output "${testExe}" --verbose
  valgrind \
    --leak-check=full \
    --error-exitcode=1 \
    --show-mismatched-frees=no \
    --show-possibly-lost=no \
    --errors-for-leak-kinds=definite \
    "${testExe}"

  echo "$1 successful - no errors reported by valgrind"
  echo "--------------------------------------------------------------------------------"
}

if [[ "$#" -gt "0" ]]; then
  testWithValgrind "${1}_test.dart"
else
  for file in "${root}/test/"*_test.dart; do
    testWithValgrind "$(basename "$file")"
  done
fi

echo "Test passed, cleaning up"
rm -rf "${testDir}"
