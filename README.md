# C64 - Centered Text Raster PRG

Audited, rebuildable preservation repository for a PAL C64 text-mode intro.
It opens with centered custom-charset titles, adds a full-width color gradient,
runs a smooth bottom scroller, synchronizes raster bars to the video frame,
and clocks a compact three-note SID arpeggio.

## Artifacts

- `c64_centered_text_raster.prg` — corrected, runnable rebuild.
- `original/deepseek_asm_20251009_v10h_text_only_stable_nowarn_v2.prg` — exact supplied binary.
- `source/` — corrected source and recovered 2 KiB charset input.

Both images are CBM PRGs loaded at `$0801`; the BASIC stub invokes `SYS 6144`
(`$1800`). The corrected image now jumps from that entry address into the
effect setup, enables SID volume before frame ticks, and is preserved at the
top level. The supplied image remains under `original/` for provenance.

## Effects

- **Centered custom-charset title:** `UBER CREW` and `2025` are measured,
  centered on screen rows 8 and 10, then written with their matching color
  spans.
- **Logo color gradient:** two 40-column color ramps make the title rows read
  as a wide, repeating highlight rather than static monochrome text.
- **Raster bars:** one VIC-II raster IRQ per PAL frame performs 16
  programmed raster-line waits and cycles a blue/cyan/white palette across
  the upper display.
- **Fine-scroll greeting line:** row 21 uses `$D016` fine scroll; every eighth
  frame shifts the character row and injects the next PETSCII byte from the
  greeting stream.
- **SID arpeggio:** the IRQ cycles three frequency words on voice 1 and keeps
  its gate and master volume enabled.

## Verification

The source build is documented in `source/` and `AUDIT.md`. Verify tracked
files with `shasum -a 256 -c SHA256SUMS.txt`.

An earlier repository image was unrelated artwork and has deliberately been
removed. Add a screenshot only by capturing `c64_centered_text_raster.prg`
running in a PAL C64 emulator; do not substitute a concept image for runtime
output.

## Rebuild and run

Requires ACME 0.97 or newer. From `source/`:

```sh
acme --strict-segments -f cbm -o ../c64_centered_text_raster.prg c64_centered_text_raster.s
```

Run the corrected image with VICE:

```sh
x64sc -autostart c64_centered_text_raster.prg
```

Press `RUN/STOP` in VICE to leave the effect. The program targets PAL timing;
run it in a PAL-configured C64 emulator for the intended raster cadence.

## Documentation and license

Function-level documentation is in docs/FUNCTIONS.md. The project is released
under GPL-3.0; see LICENSE.
