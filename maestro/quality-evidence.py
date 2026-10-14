#!/usr/bin/env python3
"""Maestro screenshot evidence gate: verifies presence/integrity, never claims visual approval.

Run after the Android/iOS test suites. Humans/agents MUST inspect the images.
"""
import argparse
import hashlib
import json
import pathlib
import struct
import sys
import tempfile
import zlib
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parent
DIRECTORIES = ("flows", "shots", "audit-dark", "audit-large", "audit-huge", "stress", "stress-android")
PROFILES = {
    "normal": lambda p: not any(x in p for x in ("dark-", "large-", "huge-", "stress-")),
    "dark": lambda p: "dark-" in p,
    "large": lambda p: "large-" in p,
    "huge": lambda p: "huge-" in p,
}

def inspect_png(file: pathlib.Path):
    with file.open("rb") as stream:
        header = stream.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError("missing PNG signature/IHDR")
    width, height = struct.unpack(">II", header[16:24])
    if width < 200 or height < 200 or width > 12000 or height > 12000:
        raise ValueError(f"implausible viewport {width}x{height}")
    digest = hashlib.sha256(file.read_bytes()).hexdigest()
    return {"width": width, "height": height, "bytes": file.stat().st_size, "sha256": digest}

def collect():
    images = {}
    for folder in DIRECTORIES:
        location = ROOT / folder
        if location.exists():
            for file in sorted(location.rglob("*.png")):
                key = str(file.relative_to(ROOT))
                try:
                    images[key] = {"status": "PASS", **inspect_png(file)}
                except (OSError, ValueError) as exc:
                    images[key] = {"status": "FAIL", "reason": str(exc)}
    return images

def evaluate(images, full):
    errors = [f"Invalid PNG: {name}: {data.get('reason')}" for name, data in images.items() if data["status"] == "FAIL"]
    coverage = {profile: sum(1 for name, image in images.items() if
                             image["status"] == "PASS" and match(name))
                for profile, match in PROFILES.items()}
    if not images:
        errors.append("No Maestro screenshots found; cannot claim visual E2E coverage")
    if full:
        for profile in PROFILES:
            if coverage[profile] == 0:
                errors.append("Missing screenshot coverage for " + profile)
    return coverage, errors

def self_test():
    with tempfile.TemporaryDirectory() as tmp:
        file = pathlib.Path(tmp) / "visual.png"
        raw = b"\x00" + b"\x00\x00\x00" * 200
        scan = raw * 200
        def chunk(name, data):
            payload = name + data
            return struct.pack(">I", len(data)) + payload + struct.pack(">I", zlib.crc32(payload))
        file.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 200, 200, 8, 2, 0, 0, 0))
                         + chunk(b"IDAT", zlib.compress(scan)) + chunk(b"IEND", b""))
        assert inspect_png(file)["width"] == 200
        _, errors = evaluate({}, True)
        assert errors
        populated = {f"{p}-test.png": {"status": "PASS"} for p in ("dark", "large", "huge")}
        populated["flow-test.png"] = {"status": "PASS"}
        assert not evaluate(populated, True)[1]
    print("PASS: valid PNG + fail-closed empty and missing-profile cases")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", choices=("ios", "android"))
    parser.add_argument("--full", action="store_true", help="Require normal/dark/large/huge variants")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--output", default="maestro-quality-evidence.json")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if not args.platform:
        parser.error("--platform required")
    images = collect()
    coverage, errors = evaluate(images, args.full)
    report = {
        "platform": args.platform, "timestamp": datetime.now(timezone.utc).isoformat(),
        "github_sha": __import__("os").environ.get("GITHUB_SHA", "local"),
        "github_run_id": __import__("os").environ.get("GITHUB_RUN_ID", "local"),
        "scope": "full" if args.full else "targeted", "profiles": coverage,
        "screenshots": images, "errors": errors,
        "visual_review": "PENDING: manual inspection required; PNG presence is not visual correctness",
        "status": "FAIL" if errors else "PASS_METADATA_ONLY",
    }
    destination = pathlib.Path(args.output)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k != "screenshots"}, indent=2))
    return bool(errors)

if __name__ == "__main__":
    sys.exit(main())
