# Artifact guide

This repository preserves the supplied centered-text PRG and its corrected
rebuild. The source snapshot and recovered charset are under source/.

The program uses CBM load address $0801 and BASIC SYS 6144. The corrected
implementation jumps directly from $1800 into `Start`, selects the custom
charset at $1000 through $D018, clears the screen and color RAM, and masks
CIA interrupt sources before installing its VIC-II raster handler.

## Effect flow

1. `Start` configures VIC bank 0, screen memory at $0400, the custom charset
   at $1000, and the standard 25-row text display.
2. `CenterPrintRow` measures each zero-terminated title and uses the screen
   and color row tables to draw it around column 20.
3. `ColorizeLogo` applies the repeating 16-entry title gradient.
4. `IRQ_Init` schedules an early first interrupt; `RasterIRQ` then has enough
   time to perform the 16-line palette sequence, advances the scroller, and
   ticks the SID arpeggio once per frame. Each raster band uses its own
   frame-offset palette entry.
5. `ScrollerTick` applies horizontal fine scrolling on row 21 and shifts in a
   new greeting character every eight frames.
6. `SID_Init` clears and configures SID voice 1 (ADSR, triangle waveform,
   gate, and volume), while `SID_Tick` rotates three note frequencies at frame
   rate.

See AUDIT.md for repair rationale and SHA256SUMS.txt for provenance.
