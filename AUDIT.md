# Audit record

## Input

- Supplied artifact: `c64_centered_text_raster.prg`
- Format: CBM PRG, load address `$0801`
- BASIC entry: `SYS 6144` (`$1800`)
- Original SHA-256: `edad9b6da96882446b41cd8eb74984dfd4ddf8d62595ff40173eae3965ed595f`
- Corrected build SHA-256: `21202abf31b544e6fd185ae6d1ffb47f24329ea30512182000a963659f25ad6e`

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

The prior README image was unrelated artwork, not a capture of this program,
and was removed. A replacement must be a PAL C64 emulator capture of the
compiled top-level PRG.

## Validation

The corrected source assembles with ACME `--strict-segments`; the binary header
and `SYS` target are checked before publication. The original input remains in
`original/` for byte-for-byte provenance.
