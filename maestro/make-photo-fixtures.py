#!/usr/bin/env python3
"""Writes four small solid-colour PNG fixtures (/tmp/fx1.png … /tmp/fx4.png) for the Photos flows. Usage: make-photo-fixtures.py [size]"""
import struct, sys, zlib

size = int(sys.argv[1]) if len(sys.argv) > 1 else 256

def png(path, rgb):
    raw = b''.join(b'\x00' + bytes(rgb) * size for _ in range(size))
    chunk = lambda t, d: struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    with open(path, 'wb') as out:
        out.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))

for i, colour in enumerate([(200, 40, 30), (30, 120, 200), (60, 160, 80), (230, 180, 40)], 1):
    png(f'/tmp/fx{i}.png', colour)
