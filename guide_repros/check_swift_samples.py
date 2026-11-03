#!/usr/bin/env python3
"""Type-check the guide excerpts and their minimal corrections against built SDK frameworks."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("products_dir", help="Xcode Build/Products/Debug-iphonesimulator directory")
args = parser.parse_args()
root = Path(__file__).resolve().parent
sdk = subprocess.check_output(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True).strip()
base = ["xcrun", "swiftc", "-typecheck", "-target", "arm64-apple-ios18.5-simulator", "-sdk", sdk, "-F", args.products_dir]

with tempfile.TemporaryDirectory(prefix="checkout-guide-") as directory:
    directory = Path(directory)
    import_control = directory / "ImportControl.swift"
    import_control.write_text((root / "CheckoutPreviewImport.swift").read_text().replace("CheckoutSessionPreview", "InternalOnlyAPI"))
    swift6_control = directory / "Swift6Control.swift"
    swift6_control.write_text((root / "CheckoutGuideAPISurface.swift").read_text().replace(
        "case .failed(let error): print(error.localizedDescription)\n        }",
        "case .failed(let error): print(error.localizedDescription)\n        @unknown default: break\n        }",
    ))
    checks = [
        ("Documented import", root / "CheckoutPreviewImport.swift", [], "cannot find type 'CheckoutController'"),
        ("Corrected import", import_control, [], None),
        ("Documented result switch, Swift 6 resilient framework", root / "CheckoutGuideAPISurface.swift", ["-swift-version", "6"], "may have additional unknown values"),
        ("Corrected result switch, Swift 6", swift6_control, ["-swift-version", "6"], None),
    ]
    for label, path, flags, expected_error in checks:
        result = subprocess.run(base + flags + [str(path)], capture_output=True, text=True)
        print(f"{label}: compiler exit {result.returncode}")
        if expected_error:
            assert result.returncode != 0 and expected_error in result.stderr, result.stderr
        else:
            assert result.returncode == 0, result.stderr
    print("Both guide compile failures reproduced; both minimal corrections compiled.")
