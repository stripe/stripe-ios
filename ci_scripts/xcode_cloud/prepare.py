#!/usr/bin/env python3
"""Prepare native Xcode Cloud actions using only the Python standard library."""

import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


def snapshot_mode():
    mode = os.environ.get("STRIPE_CI_SNAPSHOTS", "verify")
    if mode not in ("verify", "skip"):
        raise ValueError("STRIPE_CI_SNAPSHOTS must be verify or skip")
    return mode


def snapshot_classes(root):
    classes = {}
    for module in root.glob("Stripe*"):
        if not module.is_dir():
            continue
        for path in module.rglob("*Snapshot*"):
            if re.search(r"SnapshotTests?\.(swift|m)$", path.name):
                target = next((p for p in path.relative_to(root).parts if p.endswith("Tests")), None)
                if target:
                    classes.setdefault(target, []).append(path.stem)
    return classes


def prepare_source(root):
    mode = snapshot_mode()
    if os.environ.get("CI_XCODE_SCHEME") == "AllStripeFrameworks-iOS26":
        subprocess.run(["ruby", "ci_scripts/generate_ios26_testplan.rb"], cwd=root, check=True)

    # Use the same two-attempt retry policy as Bitrise, without changing committed
    # plans or scheme defaults for developers. Every action gets a fresh checkout.
    skipped = snapshot_classes(root) if mode == "skip" else {}
    paths = list(root.glob("Stripe*/**/*.xctestplan"))
    paths += list(root.glob("Example/**/*.xctestplan"))
    paths += list(root.glob("Testers/**/*.xctestplan"))
    for path in paths:
        plan = json.loads(path.read_text())
        plan.setdefault("defaultOptions", {}).update({
            "testRepetitionMode": "retryOnFailure",
            "maximumTestRepetitions": 2,
        })
        for target in plan.get("testTargets", []):
            exclusions = skipped.get(target["target"]["name"], [])
            if exclusions:
                target["skippedTests"] = sorted(set(target.get("skippedTests", []) + exclusions))
        path.write_text(json.dumps(plan, indent=2) + "\n")

    for path in root.glob("**/xcshareddata/xcschemes/*.xcscheme"):
        if any(part in ("vendor", "Pods", ".build") for part in path.parts):
            continue
        document = ET.parse(path)
        action = document.find("TestAction")
        if action is None:
            continue
        # Generation already happened with the source checkout. The scheme's
        # local-development pre-action cannot run on the separate test worker.
        if path.stem == "AllStripeFrameworks-iOS26":
            pre_actions = action.find("PreActions")
            if pre_actions is not None:
                action.remove(pre_actions)
        action.set("testRepetitionMode", "retryOnFailure")
        action.set("maximumTestRepetitions", "2")
        for testable in action.findall("Testables/TestableReference"):
            name = testable.find("BuildableReference").get("BlueprintName")
            exclusions = skipped.get(name, [])
            if exclusions:
                identifiers = testable.find("SkippedTests")
                if identifiers is None:
                    identifiers = ET.SubElement(testable, "SkippedTests")
                existing = {entry.get("Identifier") for entry in identifiers}
                for identifier in exclusions:
                    if identifier not in existing:
                        ET.SubElement(identifiers, "Test", {"Identifier": identifier})
        document.write(path, encoding="UTF-8", xml_declaration=True)
    print(f"Prepared native test actions (snapshots: {mode}, maximum attempts: 2).")


def test_targets(document):
    # Xcode emits either the original target dictionary or format version 2.
    if "TestConfigurations" in document:
        for configuration in document["TestConfigurations"]:
            yield from configuration.get("TestTargets", [])
    else:
        for name, target in document.items():
            if not name.startswith("__") and isinstance(target, dict) and "TestBundlePath" in target:
                yield target


def prepare_test(products, references):
    mode = snapshot_mode()
    if mode == "verify":
        if not references.is_dir():
            raise ValueError("Snapshot references were not copied to the test worker; check the ci_scripts symlink")
        runtime = os.environ.get("CI_TEST_DESTINATION_RUNTIME", "")
        device = os.environ.get("CI_TEST_DESTINATION_DEVICE_TYPE", "")
        if runtime not in ("iOS 16.4", "iOS 26.4.1") or device != "iPhone 12 mini":
            raise ValueError(
                "Snapshot verification requires iPhone 12 mini / iOS 16.4 or iOS 26.4.1. "
                "Use STRIPE_CI_SNAPSHOTS=skip for behavioral tests on other destinations."
            )

    paths = sorted(products.rglob("*.xctestrun"))
    if not paths:
        raise ValueError(f"No .xctestrun files found in CI_TEST_PRODUCTS_PATH ({products})")
    count = 0
    updated = []
    for path in paths:
        with path.open("rb") as handle:
            document = plistlib.load(handle)
        for target in test_targets(document):
            environment = target.setdefault("EnvironmentVariables", {})
            # Hooks' exported variables don't propagate to xcodebuild/test runners.
            environment["CI"] = "true"
            if mode == "verify":
                environment["STRIPE_SNAPSHOT_REFERENCE_DIR"] = str(references.with_name("ReferenceImages"))
            count += 1
        updated.append((path, document))
    if count == 0:
        raise ValueError("No test targets found in the Xcode Cloud test products")
    for path, document in updated:
        with path.open("wb") as handle:
            plistlib.dump(document, handle)
    print(f"Prepared {count} test targets across {len(paths)} test run files.")


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["source"]:
            prepare_source(Path(os.environ["CI_PRIMARY_REPOSITORY_PATH"]))
        elif sys.argv[1:] == ["test"]:
            prepare_test(Path(os.environ["CI_TEST_PRODUCTS_PATH"]), Path(__file__).parent / "ReferenceImages_64")
        else:
            raise ValueError("Usage: prepare.py source|test")
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(f"error: {error}")
