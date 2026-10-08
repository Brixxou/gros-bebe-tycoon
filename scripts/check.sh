#!/usr/bin/env bash
# Vérifie tout le projet : format, lint, types, tests. À lancer avant chaque commit.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

DEFS=.cache/globalTypes.d.luau
if [ ! -f "$DEFS" ]; then
	mkdir -p .cache
	curl -sSfL -o "$DEFS" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau
fi

echo "== format (stylua)"
stylua --check src tests
echo "== lint (selene)"
selene src tests
echo "== types (luau-lsp)"
rojo sourcemap -o sourcemap.json >/dev/null
luau-lsp analyze --platform=roblox --definitions=@roblox="$DEFS" --sourcemap=sourcemap.json \
	--ignore="**/Vendor/**" src
echo "== tests (lune)"
lune run tests
echo "OK"
