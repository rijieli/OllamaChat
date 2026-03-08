#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import plistlib
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import NoReturn


ROOT = Path(__file__).resolve().parent
ARCHIVES_DIR = ROOT / "Archives"
TEMPLATE_FILE = ROOT / "appcast.template.xml"
OUTPUT_FILE = ROOT / "appcast.xml"
DEFAULT_PRIVATE_KEY_FILE = Path.home() / "sparkle_private_key_ollamachat"
DERIVED_DATA_DIR = Path.home() / "Library" / "Developer" / "Xcode" / "DerivedData"
SIGN_UPDATE_PATTERNS = (
    "*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update",
    "*/SourcePackages/checkouts/Sparkle/bin/sign_update",
)


def fail(message: str) -> NoReturn:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Update Sparkle appcast.xml for an existing DMG and app bundle."
    )
    parser.add_argument(
        "--app-bundle",
        type=Path,
        help="Path to the .app bundle used to extract version information.",
    )
    parser.add_argument(
        "--dmg-path",
        type=Path,
        help="Path to the DMG file that should be signed and published in appcast.xml.",
    )
    return parser.parse_args()


def find_app_bundle(app_bundle: Path | None) -> Path:
    if app_bundle is not None:
        resolved_app_bundle = app_bundle.expanduser().resolve()
        if resolved_app_bundle.is_dir() and resolved_app_bundle.suffix == ".app":
            print(f"Using app bundle: {resolved_app_bundle.stem}")
            return resolved_app_bundle
        fail(f"Error: App bundle not found at {resolved_app_bundle}")

    if not ARCHIVES_DIR.is_dir():
        fail(f"Error: Archives directory not found at {ARCHIVES_DIR}")

    app_bundles = sorted(path for path in ARCHIVES_DIR.iterdir() if path.suffix == ".app")
    if not app_bundles:
        fail("Error: No .app bundle found in Archives directory.")

    app_bundle = app_bundles[0]
    print(f"Found app: {app_bundle.stem}")
    return app_bundle


def find_dmg_path(dmg_path: Path | None, app_bundle: Path) -> Path:
    if dmg_path is not None:
        resolved_dmg_path = dmg_path.expanduser().resolve()
        if resolved_dmg_path.is_file():
            return resolved_dmg_path
        fail(f"Error: DMG not found at {resolved_dmg_path}")

    fallback_dmg_path = (ROOT / f"{app_bundle.stem}.dmg").resolve()
    if not fallback_dmg_path.is_file():
        fail(f"Error: DMG not found at {fallback_dmg_path}")
    return fallback_dmg_path


def find_sign_update() -> Path:
    sign_update_env = os.environ.get("SPARKLE_SIGN_UPDATE")
    if sign_update_env:
        sign_update_path = Path(sign_update_env).expanduser()
        if sign_update_path.is_file():
            return sign_update_path
        fail(f"Error: SPARKLE_SIGN_UPDATE points to a missing file: {sign_update_path}")

    for executable_name in ("sign_update", "sign-update"):
        sign_update_on_path = shutil.which(executable_name)
        if sign_update_on_path:
            return Path(sign_update_on_path)

    candidates: list[Path] = []
    if DERIVED_DATA_DIR.is_dir():
        for pattern in SIGN_UPDATE_PATTERNS:
            candidates.extend(path for path in DERIVED_DATA_DIR.glob(pattern) if path.is_file())

    if not candidates:
        fail(
            "Error: Could not locate Sparkle's sign_update tool. "
            "Set SPARKLE_SIGN_UPDATE or resolve the Sparkle package in Xcode first."
        )

    candidates.sort(key=lambda path: path.stat().st_mtime, reverse=True)
    return candidates[0]


def find_private_key_file() -> Path | None:
    private_key_file = os.environ.get("SPARKLE_PRIVATE_KEY_FILE")
    if private_key_file:
        private_key_path = Path(private_key_file).expanduser()
        if private_key_path.is_file():
            return private_key_path
        fail(f"Error: SPARKLE_PRIVATE_KEY_FILE points to a missing file: {private_key_path}")

    if DEFAULT_PRIVATE_KEY_FILE.is_file():
        return DEFAULT_PRIVATE_KEY_FILE

    return None


def sign_dmg(dmg_path: Path) -> str:
    command = [str(find_sign_update()), "-p"]

    private_key_path = find_private_key_file()
    if private_key_path:
        command.extend(["--ed-key-file", str(private_key_path)])
    else:
        account = os.environ.get("SPARKLE_KEYCHAIN_ACCOUNT")
        if account:
            command.extend(["--account", account])

    command.append(str(dmg_path))

    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        details = result.stderr.strip() or result.stdout.strip() or "unknown error"
        fail(f"Error: Failed to create Sparkle signature for '{dmg_path.name}': {details}")

    signature_lines = result.stdout.strip().splitlines()
    if not signature_lines:
        fail(f"Error: Sparkle did not return a signature for '{dmg_path.name}'")

    signature = signature_lines[-1].strip()
    if not signature:
        fail(f"Error: Sparkle did not return a signature for '{dmg_path.name}'")

    return signature


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


def render_appcast(version: str, build: str, signature: str, length: int) -> str:
    if not TEMPLATE_FILE.is_file():
        fail(f"Error: Template file {TEMPLATE_FILE.name} not found")

    template = TEMPLATE_FILE.read_text(encoding="utf-8")
    return (
        template.replace("{version}", version)
        .replace("{build}", build)
        .replace("{edsign_signature}", signature)
        .replace("{edsign_length}", str(length))
    )


def git_tag_exists(tag: str) -> bool:
    result = subprocess.run(
        ["git", "rev-parse", "-q", "--verify", f"refs/tags/{tag}"],
        check=False,
        capture_output=True,
        text=True,
        cwd=ROOT,
    )
    return result.returncode == 0


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def print_release_commands(version: str, dmg_path: Path) -> None:
    create_release_command = format_command(
        [
            "gh",
            "release",
            "create",
            version,
            str(dmg_path),
            "--title",
            version,
            "--verify-tag",
            "--generate-notes",
        ]
    )
    upload_asset_command = format_command(
        ["gh", "release", "upload", version, str(dmg_path), "--clobber"]
    )
    create_tag_command = format_command(["git", "tag", version])
    push_tag_command = format_command(["git", "push", "origin", version])

    print("")
    if git_tag_exists(version):
        print("Git tag found locally.")
        print("Create a new GitHub release and upload the DMG with:")
        print(create_release_command)
    else:
        print(
            f"Warning: Git tag '{version}' is missing locally. Create and push the tag before creating the GitHub release."
        )
        print("Create and push the tag with:")
        print(create_tag_command)
        print(push_tag_command)
        print("Then create a new GitHub release and upload the DMG with:")
        print(create_release_command)

    print("Upload the DMG to an existing GitHub release with:")
    print(upload_asset_command)


def main() -> None:
    args = parse_args()
    app_bundle = find_app_bundle(args.app_bundle)
    dmg_path = find_dmg_path(args.dmg_path, app_bundle)

    plist_path = app_bundle / "Contents" / "Info.plist"
    version, build = load_bundle_versions(plist_path)
    signature = sign_dmg(dmg_path)
    appcast = render_appcast(version, build, signature, dmg_path.stat().st_size)
    OUTPUT_FILE.write_text(appcast, encoding="utf-8")

    print(f"Updated appcast.xml with version {version} (build {build})")
    print_release_commands(version, dmg_path)


if __name__ == "__main__":
    main()
