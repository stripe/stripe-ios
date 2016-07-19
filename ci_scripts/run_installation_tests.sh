gem update cocoapods --no-ri --no-rdoc
gem install xcpretty --no-ri --no-rdoc

set -euf -o pipefail && ./Tests/installation_tests/cocoapods/with_frameworks/test.sh
set -euf -o pipefail && ./Tests/installation_tests/cocoapods/without_frameworks/test.sh
set -euf -o pipefail && ./Tests/installation_tests/manual_installation/test.sh
set -euf -o pipefail && ./Tests/installation_tests/carthage/test.sh
