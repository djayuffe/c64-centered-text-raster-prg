# DeepSeek v10h text-only PRG

Private preservation repository for the supplied C64 program
`deepseek_asm_20251009_v10h_text_only_stable_nowarn_v2.prg`.

The binary is a CBM PRG loaded at `$0801`; its BASIC stub invokes `SYS 6144`
(`$1800`). The exact supplied binary is retained in `original/`. The corrected
rebuild is generated from the companion source in `source/` and is the tracked
top-level PRG.

## Build

Install ACME 0.97 or newer, then run:

```sh
acme --strict-segments -I source -f cbm \
  -o deepseek_asm_20251009_v10h_text_only_stable_nowarn_v2.prg \
  source/deepseek_asm_20251009_v10h_text_only_stable_nowarn_v2.s
```

The checked-in `source/custom_charset_1bpp.bin` is the 2 KiB charset extracted
from the supplied PRG, so the build is self-contained and offline.

## Audit

The source audit fixed the missing build input, centered-row state loss, wrong
character-ROM copy address, incorrect `$D018` screen selection, and unmasked
CIA interrupt sources. `AUDIT.md` records the exact checks and hashes.
