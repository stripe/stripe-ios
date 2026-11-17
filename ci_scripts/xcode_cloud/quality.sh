#!/bin/bash
set -euo pipefail

# shellcheck source=ci_scripts/ensure_swiftlint.sh
source ci_scripts/ensure_swiftlint.sh
# Cloud already merges PRs with their destination. Compare that checkout with
# the supplied target commit; no merge-base or full branch history is needed.
python3 - <<'PY'
import os
import subprocess

base = os.environ.get("CI_PULL_REQUEST_TARGET_COMMIT")
if base:
    if subprocess.run(["git", "cat-file", "-e", base + "^{commit}"], stderr=subprocess.DEVNULL).returncode:
        subprocess.run(["git", "fetch", "--no-tags", "--depth=1", "origin", base], check=True)
    command = ["git", "diff", "--name-only", "--diff-filter=ACMR", "-z", base, "HEAD", "--", "*.swift"]
else:
    command = ["git", "ls-files", "-z", "--", "*.swift"]
files = [name for name in subprocess.check_output(command).decode().split("\0") if name]
if files:
    env = dict(os.environ, SCRIPT_INPUT_FILE_COUNT=str(len(files)))
    env.update({f"SCRIPT_INPUT_FILE_{index}": name for index, name in enumerate(files)})
    subprocess.run([env["SWIFTLINT"], "--strict", "--use-script-input-files", "--config", ".swiftlint.yml"], env=env, check=True)
PY
ruby ci_scripts/check_version.rb
ruby ci_scripts/check_paymentsheet_test_sharding.rb
./ci_scripts/check_image_format.sh
bundle exec ./ci_scripts/check_for_new_localized_strings.sh
ruby ci_scripts/generate_objc_enum_string_values.rb
./ci_scripts/check_for_missing_custom_string_convertible.sh
ruby ci_scripts/check_spm_warnings.rb
ruby ci_scripts/tests/framework_architecture_validator_test.rb
python3 -B -m unittest discover -s ci_scripts/tests -p 'xcode_cloud_test.py'
