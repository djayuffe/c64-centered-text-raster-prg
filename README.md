# C64 v10h Text PRG

Private preservation repository for the supplied C64 program
the supplied v10h text-mode program.

## Artifacts

- `c64_centered_text_raster.prg` — corrected rebuild.
- `original/deepseek_asm_20251009_v10h_text_only_stable_nowarn_v2.prg` — exact supplied binary.
- `source/` — corrected source and recovered 2 KiB charset input.

Both images are CBM PRGs loaded at `$0801`; the BASIC stub invokes `SYS 6144`
(`$1800`). The top-level image is the corrected build; the supplied image is
preserved under `original/` for provenance.

## Verification

The source build is documented in `source/` and `AUDIT.md`. Verify tracked
files with `shasum -a 256 -c SHA256SUMS.txt`.
