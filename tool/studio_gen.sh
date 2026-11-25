#!/usr/bin/env bash
# Re-generates the Studio data layer. Usage: tool/studio_gen.sh <contract_dir>
set -euo pipefail
cd "$(dirname "$0")/.."
python tool/studio_gen_contract.py "$1"
dart format lib/src/studio/data test/studio/data
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/src/studio/**"
# build_runner deletes POS generated files it was told not to rebuild: restore them.
git ls-files -d | grep -v '^lib/src/studio' | xargs -r git checkout --
