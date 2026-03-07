#!/usr/bin/env python3

from __future__ import annotations

import plistlib
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import NoReturn


ROOT = Path(__file__).resolve().parent
ARCHIVES_DIR = ROOT / "Archives"
TEMPLATE_FILE = ROOT / "appcast.template.xml"
OUTPUT_FILE = ROOT / "appcast.xml"
IDENTITY_RE = re.compile(r'^\s*\d+\)\s+([0-9A-F]+)\s+"([^"]+)"$')
TEAM_RE = re.compile(r"\(([A-Z0-9]+)\)$")


@dataclass(frozen=True)
class SigningIdentity:
    fingerprint: str
    name: str
    team_id: str


def fail(message: str) -> NoReturn:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def find_app_bundle() -> Path:
    if not ARCHIVES_DIR.is_dir():
        fail(f"Error: Archives directory not found at {ARCHIVES_DIR}")

    app_bundles = sorted(path for path in ARCHIVES_DIR.iterdir() if path.suffix == ".app")
    if not app_bundles:
        fail("Error: No .app bundle found in Archives directory.")

    app_bundle = app_bundles[0]
    print(f"Found app: {app_bundle.stem}")
    return app_bundle


def find_signing_identities() -> list[SigningIdentity]:
    result = subprocess.run(
        ["security", "find-identity", "-v", "-p", "codesigning"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        details = result.stderr.strip() or result.stdout.strip() or "unknown error"
        fail(f"Error: Failed to list local code signing identities: {details}")

    identities: list[SigningIdentity] = []
    for line in result.stdout.splitlines():
        identity_match = IDENTITY_RE.match(line)
        if identity_match is None:
            continue

        fingerprint, name = identity_match.groups()
        if not name.startswith("Developer ID Application:"):
            continue

        team_match = TEAM_RE.search(name)
        if team_match is None:
            fail(f"Error: Could not parse team ID from signing identity '{name}'")

        identities.append(
            SigningIdentity(
                fingerprint=fingerprint,
                name=name,
                team_id=team_match.group(1),
            )
        )

    if not identities:
        fail("Error: No 'Developer ID Application' signing identities were found in Keychain.")

    return identities


def choose_signing_identity(identities: list[SigningIdentity]) -> SigningIdentity:
    print("Available Developer ID signing identities:")
    for index, identity in enumerate(identities, start=1):
        print(f"{index}. {identity.team_id}  {identity.name}")

    while True:
        choice = input("Select identity number for DMG signing: ").strip()
        if not choice.isdigit():
            print("Enter a number from the list.", file=sys.stderr)
            continue

        selection = int(choice)
        if 1 <= selection <= len(identities):
            identity = identities[selection - 1]
            print(f"Using signing identity: {identity.name}")
            return identity

        print("Selection is out of range.", file=sys.stderr)


def sign_dmg(dmg_path: Path, identity: SigningIdentity) -> None:
    result = subprocess.run(
        ["codesign", "--force", "--sign", identity.name, "--timestamp", str(dmg_path)],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        details = result.stderr.strip() or result.stdout.strip() or "unknown error"
        fail(f"Error: Failed to sign DMG with '{identity.name}': {details}")


def load_bundle_versions(plist_path: Path) -> tuple[str, str]:
    if not plist_path.is_file():
        fail(f"Error: Info.plist not found at {plist_path}")

    with plist_path.open("rb") as plist_file:
        info = plistlib.load(plist_file)

    version = info.get("CFBundleShortVersionString")
    build = info.get("CFBundleVersion")
    if not version or not build:
        fail("Error: Could not extract version or build number from Info.plist")

    return str(version), str(build)


def render_appcast(version: str, build: str, length: int) -> str:
    if not TEMPLATE_FILE.is_file():
        fail(f"Error: Template file {TEMPLATE_FILE.name} not found")

    template = TEMPLATE_FILE.read_text(encoding="utf-8")
    return (
        template.replace("{version}", version)
        .replace("{build}", build)
        .replace("{edsign_length}", str(length))
    )


def main() -> None:
    app_bundle = find_app_bundle()
    dmg_path = ROOT / f"{app_bundle.stem}.dmg"
    if not dmg_path.is_file():
        fail(f"Error: DMG not found at {dmg_path}")

    signing_identity = choose_signing_identity(find_signing_identities())
    sign_dmg(dmg_path, signing_identity)

    plist_path = app_bundle / "Contents" / "Info.plist"
    version, build = load_bundle_versions(plist_path)
    appcast = render_appcast(version, build, dmg_path.stat().st_size)
    OUTPUT_FILE.write_text(appcast, encoding="utf-8")

    print(f"Updated appcast.xml with version {version} (build {build})")


if __name__ == "__main__":
    main()
