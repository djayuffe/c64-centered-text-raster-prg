# C64 - Centered Text Raster PRG

![C64 effect preview](docs/preview.png)

Visual preview asset for this effect; run the VICE command below for an emulator capture.

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

## Rebuild and run

Requires ACME 0.97 or newer. From `source/`:

```sh
acme --strict-segments -f cbm -o ../c64_centered_text_raster.prg c64_centered_text_raster.s
```

Run the corrected image with VICE:

```sh
x64sc -autostart c64_centered_text_raster.prg
```

## Documentation and license

Function-level documentation is in docs/FUNCTIONS.md. The project is released
under GPL-3.0; see LICENSE.
