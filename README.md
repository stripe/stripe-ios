# Stripe iOS SDK
[![Travis](https://img.shields.io/travis/stripe/stripe-ios/master.svg?style=flat)](https://travis-ci.org/stripe/stripe-ios)
[![CocoaPods](https://img.shields.io/cocoapods/v/Stripe.svg?style=flat)](http://cocoapods.org/?q=author%3Astripe%20name%3Astripe)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/l/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios/blob/master/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/p/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios#)

The Stripe iOS SDK make it easy to collect your users' credit card details inside your iOS app. By creating [tokens](https://stripe.com/docs/api#tokens), Stripe handles the bulk of PCI compliance by preventing sensitive card data from hitting your server (for more, see [our article about PCI compliance](https://support.stripe.com/questions/do-i-need-to-be-pci-compliant-what-do-i-have-to-do)).

We also offer [seamless integration](https://stripe.com/apple-pay) with [Apple Pay](https://www.apple.com/apple-pay/) that will allow you to securely collect payments from your customers in a way that prevents them from having to re-enter their credit card information.

> Note: we've greatly simplified the integration for `STPPaymentContext` in [v11.0.0](https://github.com/stripe/stripe-ios/releases/v11.0.0). If you integrated `STPPaymentContext` prior to this and you're interested in migrating, we've written a [migration guide](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md#migration-from-versions--1100).

## Releases

We recommend you only use official versioned releases of the sdk (accessible from Github's [Releases](https://github.com/stripe/stripe-ios/releases) page) as the master branch is considered unstable.

If you're reading this on github.com, make sure you are looking at the version that matches the release you have installed, otherwise the instructions and example code may be mismatched. You can read the latest released version of this readme and browse the associated code on Github via [this link](https://github.com/stripe/stripe-ios/tree/v11.2.0).

## Requirements
Our SDK is compatible with iOS apps supporting iOS 8.0 and above. It requires Xcode 8.0+ to build the source.

If you need iOS 7 or Xcode 7 compatibility, the last supported SDK release is version 8.0.7.

## Integration

We've written a [guide](https://stripe.com/docs/mobile/ios) that explains everything from installation, to creating payment tokens, to Apple Pay integration and more.

For more fine-grained information on all of the classes and methods in our SDK, consult our [full SDK reference](http://stripe.github.io/stripe-ios/docs/index.html).

## Example apps

There are 2 example apps included in the repository:
- Standard Integration (Swift) shows an integration using our prebuilt UI components.
- Custom Integration (ObjC) shows how to use our low-level methods to accept payments using several different payment methods.

To build the example apps, you'll need to first run `./setup.sh`. Then, open `Stripe.xcworkspace` and choose the appropriate scheme.

### Getting started with the iOS example apps

Note: all the example apps require Xcode 8.0 to build and run.

Before you can run the apps, you need to provide them with your Stripe publishable key.

1. If you haven't already, sign up for a [Stripe account](https://dashboard.stripe.com/register) (it takes seconds). Then go to https://dashboard.stripe.com/account/apikeys.
2. Replace the `stripePublishableKey` constant in CheckoutViewController.swift (for the Standard Integration app) or Constants.m (for the Custom Integration app) with your Test Publishable Key.
3. Head to https://github.com/stripe/example-ios-backend/tree/v11.0.0 and click "Deploy to Heroku" (you may have to sign up for a Heroku account as part of this process). Provide your Stripe test secret key for the STRIPE_TEST_SECRET_KEY field under 'Env'. Click "Deploy for Free".
4. Replace the `backendBaseURL` variable in the example iOS app with the app URL Heroku provides you with (e.g. "https://my-example-app.herokuapp.com")

After this is done, you can make test payments through the app and see them in your Stripe dashboard. Head to https://stripe.com/docs/testing#cards for a list of test card numbers.

## card.io

To add card scanning capabilities to our prebuilt UI components, you can simply [install card.io](https://github.com/card-io/card.io-iOS-SDK#setup) alongside our SDK. You'll also need to set `NSCameraUsageDescription` in your application's plist, and provide a reason for accessing the camera (e.g. "To scan cards").

To try this out, you can run `./install_cardio.rb`, which will download and install card.io in Standard Integration (Swift). Now, when you run the example app on a device, you'll see a "Scan Card" button when adding a new card.

## Running the tests

1. Install Carthage (if you have homebrew installed, `brew install carthage`)
2. From the root of the repo, install test dependencies by running `carthage bootstrap --platform ios --configuration Release --no-use-binaries`
3. Open Stripe.xcworkspace
4. Choose the "StripeiOS" scheme with the iPhone 6, iOS 10.3 simulator (required for snapshot tests to pass)
5. Run Product -> Test

## Migrating from older versions

See `MIGRATING.md`
