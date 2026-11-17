"""Regression tests for Cloud's separate source and test-worker lifecycles."""

import importlib.util
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("prepare", ROOT / "ci_scripts/xcode_cloud/prepare.py")
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


class XcodeCloudTests(unittest.TestCase):
    def setUp(self):
        # Keep test scratch data in the repository, including on devboxes.
        scratch = ROOT / "build/xcode-cloud-script-tests"
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = patch.dict(os.environ, {
            "STRIPE_CI_SNAPSHOTS": "verify",
            "CI_TEST_DESTINATION_RUNTIME": "iOS 16.4",
            "CI_TEST_DESTINATION_DEVICE_TYPE": "iPhone 12 mini",
        })
        self.env.start()
        self.addCleanup(self.env.stop)

    def write_json(self, relative, data):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data))
        return path

    def write_run(self, document, fmt=plistlib.FMT_XML):
        path = self.root / "products/SDK tests.xctestrun"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(plistlib.dumps(document, fmt=fmt))
        return path

    def references(self):
        path = self.root / "copied scripts/ReferenceImages_64"
        path.mkdir(parents=True)
        return path

    def test_worker_relocates_references_and_preserves_test_settings(self):
        references = self.references()
        target = {
            "TestBundlePath": "__TESTROOT__/SDKTests.xctest",
            "EnvironmentVariables": {"EXISTING": "value"},
            "OnlyTestIdentifiers": ["SomeTests/testExample"],
            "SkipTestIdentifiers": ["SkippedTests"],
        }
        path = self.write_run({"TestConfigurations": [{"TestTargets": [target]}]}, plistlib.FMT_BINARY)
        prepare.prepare_test(path.parent, references)
        actual = plistlib.loads(path.read_bytes())["TestConfigurations"][0]["TestTargets"][0]
        self.assertEqual(actual["OnlyTestIdentifiers"], target["OnlyTestIdentifiers"])
        self.assertEqual(actual["SkipTestIdentifiers"], target["SkipTestIdentifiers"])
        self.assertEqual(actual["EnvironmentVariables"], {
            "EXISTING": "value", "CI": "true",
            "STRIPE_SNAPSHOT_REFERENCE_DIR": str(references.with_name("ReferenceImages")),
        })

    def test_original_test_run_format_preserves_metadata(self):
        path = self.write_run({
            "SDKTests": {"TestBundlePath": "SDKTests.xctest"},
            "__xctestrun_metadata__": {"FormatVersion": 1},
        })
        prepare.prepare_test(path.parent, self.references())
        actual = plistlib.loads(path.read_bytes())
        self.assertEqual(actual["__xctestrun_metadata__"], {"FormatVersion": 1})
        self.assertEqual(actual["SDKTests"]["EnvironmentVariables"]["CI"], "true")

    def test_rejects_missing_products_or_references(self):
        with self.assertRaisesRegex(ValueError, "references were not copied"):
            prepare.prepare_test(self.root, self.root / "missing")
        with self.assertRaisesRegex(ValueError, "No .xctestrun"):
            prepare.prepare_test(self.root, self.references())

    def test_rejects_unknown_test_run_format(self):
        path = self.write_run({"Unexpected": {"Other": "value"}})
        with self.assertRaisesRegex(ValueError, "No test targets"):
            prepare.prepare_test(path.parent, self.references())

    def test_rejects_snapshot_destination_without_matching_baselines(self):
        references = self.references()
        path = self.write_run({"SDKTests": {"TestBundlePath": "SDKTests.xctest"}})
        for key, value in [("CI_TEST_DESTINATION_RUNTIME", "iOS 18.5"),
                           ("CI_TEST_DESTINATION_DEVICE_TYPE", "iPhone 16")]:
            with patch.dict(os.environ, {key: value}):
                with self.assertRaisesRegex(ValueError, "Snapshot verification requires"):
                    prepare.prepare_test(path.parent, references)

    def test_behavioral_runs_need_neither_references_nor_a_snapshot_runtime(self):
        path = self.write_run({"SDKTests": {"TestBundlePath": "SDKTests.xctest"}})
        with patch.dict(os.environ, {"STRIPE_CI_SNAPSHOTS": "skip", "CI_TEST_DESTINATION_RUNTIME": "iOS 18.5"}):
            prepare.prepare_test(path.parent, self.root / "missing")
        self.assertNotIn("STRIPE_SNAPSHOT_REFERENCE_DIR", plistlib.loads(path.read_bytes())["SDKTests"]["EnvironmentVariables"])

    def test_source_skips_snapshots_without_losing_existing_selections(self):
        snapshot = self.root / "StripeCore/StripeCoreTests/ViewSnapshotTests.swift"
        snapshot.parent.mkdir(parents=True)
        snapshot.touch()
        path = self.write_json("StripeCore/Tests.xctestplan", {
            "configurations": [], "defaultOptions": {"region": "US"},
            "testTargets": [{"target": {"name": "StripeCoreTests"},
                             "selectedTests": ["BehaviorTests", "ViewSnapshotTests"],
                             "skippedTests": ["BehaviorTests/testFlaky()"]}],
        })
        scheme = self.root / "Stripe.xcworkspace/xcshareddata/xcschemes/Tests.xcscheme"
        scheme.parent.mkdir(parents=True)
        scheme.write_text('<Scheme><TestAction><Testables><TestableReference><BuildableReference BlueprintName="StripeCoreTests" />'
                          '<SkippedTests><Test Identifier="ExistingSkip" /></SkippedTests>'
                          '</TestableReference></Testables></TestAction></Scheme>')
        with patch.dict(os.environ, {"STRIPE_CI_SNAPSHOTS": "skip"}):
            prepare.prepare_source(self.root)
            prepare.prepare_source(self.root)
        plan = json.loads(path.read_text())
        self.assertEqual(plan["defaultOptions"]["region"], "US")
        self.assertEqual(plan["defaultOptions"]["maximumTestRepetitions"], 2)
        target = plan["testTargets"][0]
        self.assertEqual(target["selectedTests"], ["BehaviorTests", "ViewSnapshotTests"])
        self.assertEqual(target["skippedTests"], ["BehaviorTests/testFlaky()", "ViewSnapshotTests"])
        identifiers = ET.parse(scheme).findall(".//SkippedTests/Test")
        self.assertEqual([test.get("Identifier") for test in identifiers], ["ExistingSkip", "ViewSnapshotTests"])

    def test_verification_keeps_all_snapshot_tests(self):
        path = self.write_json("StripeCore/Tests.xctestplan", {
            "testTargets": [{"target": {"name": "StripeCoreTests"}}],
        })
        prepare.prepare_source(self.root)
        self.assertNotIn("skippedTests", json.loads(path.read_text())["testTargets"][0])

    def test_payment_sheet_shards_remain_complete_after_preparation(self):
        destination = self.root / "Example/PaymentSheet Example"
        destination.mkdir(parents=True)
        for path in (ROOT / "Example/PaymentSheet Example").glob("*.xctestplan"):
            shutil.copy(path, destination)
        prepare.prepare_source(self.root)
        plans = [json.loads((destination / f"PaymentSheet Example-Shard{index}.xctestplan").read_text()) for index in range(1, 5)]
        selected = [test for plan in plans[:3] for test in plan["testTargets"][0]["selectedTests"]]
        self.assertEqual(len(selected), len(set(selected)))
        self.assertEqual(sorted(selected), plans[3]["testTargets"][0]["skippedTests"])
        self.assertNotIn("selectedTests", plans[3]["testTargets"][0])

    def test_ios26_generation_runs_before_preparation(self):
        scheme = self.root / "Stripe.xcworkspace/xcshareddata/xcschemes/AllStripeFrameworks-iOS26.xcscheme"
        scheme.parent.mkdir(parents=True)
        scheme.write_text('<Scheme><TestAction><PreActions><ExecutionAction /></PreActions></TestAction></Scheme>')
        with patch.dict(os.environ, {"CI_XCODE_SCHEME": "AllStripeFrameworks-iOS26"}), patch.object(prepare.subprocess, "run") as run:
            prepare.prepare_source(self.root)
        run.assert_called_once_with(["ruby", "ci_scripts/generate_ios26_testplan.rb"], cwd=self.root, check=True)
        self.assertIsNone(ET.parse(scheme).find("TestAction/PreActions"))

    def test_invalid_mode_fails_before_changing_files(self):
        with patch.dict(os.environ, {"STRIPE_CI_SNAPSHOTS": "typo"}):
            with self.assertRaisesRegex(ValueError, "verify or skip"):
                prepare.prepare_source(self.root)

    def test_unrelated_workflows_do_not_require_a_checkout(self):
        for script in ("ci_post_clone.sh", "ci_pre_xcodebuild.sh", "ci_post_xcodebuild.sh"):
            result = subprocess.run([str(ROOT / "ci_scripts" / script)], cwd=self.root,
                                    env={"PATH": os.environ["PATH"], "CI_XCODEBUILD_ACTION": "test-without-building"},
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_native_test_hook_runs_without_source_checkout(self):
        scripts = self.root / "worker/ci_scripts"
        shutil.copytree(ROOT / "ci_scripts", scripts, ignore=shutil.ignore_patterns("ReferenceImages_64"))
        run_file = self.write_run({"SDKTests": {"TestBundlePath": "SDKTests.xctest"}})
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        xcrun = bin_dir / "xcrun"
        xcrun.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$COMMAND_LOG"\n')
        xcrun.chmod(0o755)
        log = self.root / "commands"
        env = dict(os.environ, PATH=str(bin_dir) + os.pathsep + os.environ["PATH"],
                   STRIPE_XCODE_CLOUD_CI="1", STRIPE_CI_SNAPSHOTS="skip",
                   CI_XCODEBUILD_ACTION="test-without-building", CI_TEST_PRODUCTS_PATH=str(run_file.parent),
                   CI_TEST_DESTINATION_UDID="cloud-device", CI_PRIMARY_REPOSITORY_PATH="/nonexistent",
                   COMMAND_LOG=str(log))
        result = subprocess.run([str(scripts / "ci_pre_xcodebuild.sh")], cwd=self.root,
                                env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("simctl bootstatus cloud-device -b", log.read_text())
        self.assertIn("simctl spawn cloud-device defaults write", log.read_text())
        self.assertEqual(plistlib.loads(run_file.read_bytes())["SDKTests"]["EnvironmentVariables"]["CI"], "true")

    def test_native_test_hook_propagates_preparation_errors(self):
        result = subprocess.run([str(ROOT / "ci_scripts/ci_pre_xcodebuild.sh")], cwd=self.root,
                                env=dict(os.environ, STRIPE_XCODE_CLOUD_CI="1", STRIPE_CI_SNAPSHOTS="skip",
                                         CI_XCODEBUILD_ACTION="test-without-building", CI_TEST_PRODUCTS_PATH=str(self.root)),
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No .xctestrun", result.stderr)

    def test_references_are_a_valid_tracked_symlink(self):
        references = ROOT / "ci_scripts/xcode_cloud/ReferenceImages_64"
        self.assertTrue(references.is_symlink())
        self.assertEqual(references.resolve(), ROOT / "Tests/ReferenceImages_64")


if __name__ == "__main__":
    unittest.main()
