#!/usr/bin/env bash
# Copyright (C) 2026 Ulf Bertilsson
# SPDX-License-Identifier: GPL-3.0-or-later
# Build and validate every generated release artifact.
set -euo pipefail

acme --strict-segments -I source -f cbm \
  -o c64_centered_text_raster.prg source/c64_centered_text_raster.s
python3 tools/render_preview.py
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c SHA256SUMS.txt
else
  shasum -a 256 -c SHA256SUMS.txt
fi
git diff --exit-code -- c64_centered_text_raster.prg docs/runtime-frame.png
