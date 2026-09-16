# Artifact guide

This repository preserves the supplied centered-text PRG and its corrected
rebuild. The source snapshot and recovered charset are under source/.

The program uses CBM load address $0801 and BASIC SYS 6144. The corrected
implementation fixes character-ROM copying, $D018 screen/charset selection,
row/color preservation, and CIA interrupt masking.

See AUDIT.md for repair rationale and SHA256SUMS.txt for provenance.
