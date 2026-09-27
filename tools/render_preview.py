#!/usr/bin/env python3
"""Render a deterministic first-frame preview from the assembled source data.

This does not emulate a C64. It renders the initialized text-mode state used
by `source/c64_centered_text_raster.s`: the embedded 1 bpp charset, centered
title rows, their color gradients, and one reproducible raster-bar phase.
"""

from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
CHARSET = (ROOT / "source" / "custom_charset_1bpp.bin").read_bytes()
OUT = ROOT / "docs" / "runtime-frame.png"

# Pepto PAL palette, represented as RGB for documentation previewing.
PALETTE = (
    (0, 0, 0), (255, 255, 255), (104, 55, 43), (112, 164, 178),
    (111, 61, 134), (88, 141, 67), (53, 40, 121), (184, 199, 111),
    (111, 79, 37), (67, 57, 0), (154, 103, 89), (68, 68, 68),
    (108, 108, 108), (154, 210, 132), (108, 94, 181), (149, 149, 149),
)
WIDTH, HEIGHT, SCALE = 320, 200, 3
RASTER_LINES = (50, 58, 66, 74, 82, 90, 98, 106, 114, 122, 130, 138, 146, 154, 162, 170)
BAR_COLORS = (2, 6, 3, 1, 3, 6, 2, 0, 2, 6, 3, 1, 3, 6, 2, 0)
LOGO_GRADIENT = (1, 15, 14, 6, 14, 15, 1, 1, 15, 14, 6, 14, 15, 1, 1, 1)


def screen_code(character: str) -> int:
    if "A" <= character <= "Z":
        return ord(character) - ord("A") + 1
    if "0" <= character <= "9":
        return ord(character)
    return 0x20


def chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def main() -> None:
    pixels = [[PALETTE[0] for _ in range(WIDTH)] for _ in range(HEIGHT)]

    # FrameCount = 0: the IRQ changes the background at each listed line.
    color = 0
    bar_index = 0
    for y in range(HEIGHT):
        while bar_index < len(RASTER_LINES) and y >= RASTER_LINES[bar_index]:
            color = BAR_COLORS[bar_index]
            bar_index += 1
        pixels[y] = [PALETTE[color] for _ in range(WIDTH)]

    screen = [[0x20 for _ in range(40)] for _ in range(25)]
    colors = [[1 for _ in range(40)] for _ in range(25)]
    for row, text in ((8, "UBER CREW"), (10, "2025")):
        column = (40 - len(text)) // 2
        for offset, character in enumerate(text):
            screen[row][column + offset] = screen_code(character)
        for column_index in range(40):
            colors[row][column_index] = LOGO_GRADIENT[column_index % len(LOGO_GRADIENT)]

    for row in range(25):
        for column in range(40):
            code = screen[row][column]
            foreground = PALETTE[colors[row][column]]
            glyph = CHARSET[code * 8:(code + 1) * 8]
            for glyph_y, bits in enumerate(glyph):
                for glyph_x in range(8):
                    if bits & (0x80 >> glyph_x):
                        pixels[row * 8 + glyph_y][column * 8 + glyph_x] = foreground

    scaled_rows = []
    for row in pixels:
        scaled = [pixel for pixel in row for _ in range(SCALE)]
        encoded = b"\x00" + bytes(component for pixel in scaled for component in pixel)
        scaled_rows.extend([encoded] * SCALE)
    raw = b"".join(scaled_rows)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", WIDTH * SCALE, HEIGHT * SCALE, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    OUT.write_bytes(png)


if __name__ == "__main__":
    main()
