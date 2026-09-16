# Audit record

## Input

- Supplied artifact: `c64_centered_text_raster.prg`
- Format: CBM PRG, load address `$0801`
- BASIC entry: `SYS 6144` (`$1800`)
- Original SHA-256: `edad9b6da96882446b41cd8eb74984dfd4ddf8d62595ff40173eae3965ed595f`
- Corrected build SHA-256: `dd2b7a716f4f7f2c7c700cdf76832ef5cf91deaba52cce3c51e615163d64d967`

## Corrective work

The companion source is the corrected form. It embeds the exact 2 KiB charset
recovered from the input image, preserves the caller's row while measuring
text, writes the requested color span, copies character ROM from `$D000`,
keeps screen `$0400` with charset `$1000` (`$D018=$14`), and masks CIA IRQs
before installing the raster handler.

## Validation

The corrected source assembles with ACME `--strict-segments`; the binary header
and `SYS` target are checked before publication. The original input remains in
`original/` for byte-for-byte provenance.
