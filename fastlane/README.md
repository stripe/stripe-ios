fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios screenshots
```
fastlane ios screenshots
```
Generate new localized screenshots
### ios all_ci
```
fastlane ios all_ci
```

### ios linting_tests
```
fastlane ios linting_tests
```

### ios install_tests
```
fastlane ios install_tests
```

### ios preflight
```
fastlane ios preflight
```

### ios ci_builds
```
fastlane ios ci_builds
```

### ios stripeios_tests
```
fastlane ios stripeios_tests
```

### ios stripecore_tests
```
fastlane ios stripecore_tests
```

### ios stripeidentity_tests
```
fastlane ios stripeidentity_tests
```

### ios paymentsheet_tests
```
fastlane ios paymentsheet_tests
```

### ios basic_integration_tests
```
fastlane ios basic_integration_tests
```

### ios integration_all
```
fastlane ios integration_all
```

### ios ui_tests
```
fastlane ios ui_tests
```

### ios legacy_tests_11
```
fastlane ios legacy_tests_11
```

### ios legacy_tests_12
```
fastlane ios legacy_tests_12
```

### ios e2e_only
```
fastlane ios e2e_only
```

### ios analyze
```
fastlane ios analyze
```

### ios builds
```
fastlane ios builds
```

### ios install_cocoapods_without_frameworks_objc
```
fastlane ios install_cocoapods_without_frameworks_objc
```

### ios installation_cocoapods_frameworks_objc
```
fastlane ios installation_cocoapods_frameworks_objc
```

### ios installation_cocoapods_frameworks_swift
```
fastlane ios installation_cocoapods_frameworks_swift
```

### ios installation_carthage
```
fastlane ios installation_carthage
```

### ios installation_spm_objc
```
fastlane ios installation_spm_objc
```

### ios installation_spm_swift
```
fastlane ios installation_spm_swift
```

### ios check_docs
```
fastlane ios check_docs
```

### ios tests
```
fastlane ios tests
```

### ios store
```
fastlane ios store
```

  Submit a new build to TestFlight.
  #### Example:
  ```fastlane ios store app:identity_example username:mludowise@stripe.com```
  #### Options:
  | Argument | Description | Expected Value |
  | -------- | ----------- | -------------- |
  | `app` | The app to build and submit (required). | <ul><li>`identity_example` – Demonstrates capabilities of IdentityVerificationSheet</li></ul> |
  | `username` | Your Apple Developer username (required). | {{youruser}}@stripe.com |
  
### ios store_test
```
fastlane ios store_test
```

  Test building the way we do for TestFlight submission. No submissions made.
  #### Example:
  ```fastlane ios test_store app:identity_example username:mludowise@stripe.com```
  #### Options:
  | Argument | Description | Expected Value |
  | -------- | ----------- | -------------- |
  | `app` | The app to build and submit (required). | <ul><li>`identity_example` – Demonstrates capabilities of IdentityVerificationSheet</li></ul> |
  | `username` | Your Apple Developer username (required). | {{youruser}}@stripe.com |
  

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
