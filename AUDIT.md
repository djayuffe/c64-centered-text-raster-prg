# Audit record

## Input

- Supplied artifact: `c64_centered_text_raster.prg`
- Format: CBM PRG, load address `$0801`
- BASIC entry: `SYS 6144` (`$1800`)
- Original SHA-256: `edad9b6da96882446b41cd8eb74984dfd4ddf8d62595ff40173eae3965ed595f`
- Corrected build SHA-256: `bf2e5f8b7fa5407d1c37ca97a17f779e04caeeb0bca4ea743c38b570d33d053e`

## Corrective work

The companion source is the corrected form. It embeds the exact 2 KiB charset
recovered from the input image, preserves the caller's row while measuring
text, writes the requested color span, keeps screen `$0400` with charset
`$1000` (`$D018=$14`), masks CIA IRQs before installing the raster handler,
and initializes SID master volume before the frame arpeggio starts.

The audit also corrected the executable entry: the BASIC `SYS 6144` target
now jumps directly to `Start` instead of returning through an auxiliary
charset-copy routine.

The raster handler now advances directly after each programmed low raster
line. The former `$D011`-MSB wait only completes above line 255, stretching a
single intended bar across almost an entire frame; removing it restores the
16-line palette sequence.

The handler now starts at line 32, leaving a full timing margin before its
first programmed hit at line 50. It offsets the palette lookup by the current
bar index, so all 16 bands are visible rather than being overwritten with one
frame-wide color. SID voice 1 is reset to a known ADSR, waveform, gate, and
frequency before the first frame tick; VIC bank-select pins are explicitly
configured as CIA2 outputs.

The prior README image was unrelated artwork, not a capture of this program,
and was removed. A replacement must be a PAL C64 emulator capture of the
compiled top-level PRG.

## Validation

The corrected source assembles with ACME `--strict-segments`; the binary header
and `SYS` target are checked before publication. The original input remains in
`original/` for byte-for-byte provenance.
