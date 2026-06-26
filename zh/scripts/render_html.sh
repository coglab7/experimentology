#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_PARENT="${TMPDIR:-/tmp}"
BUILD_DIR="$(mktemp -d "${TMP_PARENT%/}/experimentology-zh-build.XXXXXX")"

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

cp "$ROOT_DIR/zh/config/_quarto.yml" "$BUILD_DIR/_quarto.yml"
cp "$ROOT_DIR/_setup.qmd" "$BUILD_DIR/_setup.qmd"
perl -0pi -e 's/# load font for plots\n\.font <- "Source Sans Pro"\nif \(!\(\.font %in% sysfonts::font_families\(\)\)\)\n  sysfonts::font_add_google\(\.font, \.font\)\nshowtext::showtext_auto\(\)/# load font for plots\n.font <- "sans"\nshowtext::showtext_auto()/s' "$BUILD_DIR/_setup.qmd"

for path in _variables.yml experimentology.bib _extensions data helper images md resources; do
  if [[ -e "$ROOT_DIR/$path" ]]; then
    ln -s "$ROOT_DIR/$path" "$BUILD_DIR/$path"
  fi
done

cp "$ROOT_DIR"/zh/chapters/*.qmd "$BUILD_DIR"/

(
  cd "$BUILD_DIR"
  RENV_PROJECT="$ROOT_DIR" \
  R_PROFILE_USER="$ROOT_DIR/renv/activate.R" \
    quarto render --to html "$@"
)

rm -rf "$ROOT_DIR/_book"
cp -R "$BUILD_DIR/_book" "$ROOT_DIR/_book"
printf 'Rendered Chinese HTML copied to %s\n' "$ROOT_DIR/_book"
