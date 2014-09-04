# Stripe iOS Bindings

[![Build Status](https://travis-ci.org/stripe/stripe-ios.svg?branch=master)](https://travis-ci.org/stripe/stripe-ios)

The Stripe iOS bindings make it easy to collect your users' credit card details inside your iOS app. By creating [tokens](https://stripe.com/docs/api#tokens), Stripe handles the bulk of PCI compliance by preventing sensitive card data from hitting your server (for more, see [our article about PCI compliance](https://support.stripe.com/questions/do-i-need-to-be-pci-compliant-what-do-i-have-to-do)).

We've written a [tutorial](https://stripe.com/docs/mobile/ios) that explains how to get started with Stripe on iOS, or read on!

## Installation

You can add Stripe to your project via Cocoapods or include it manually. These bindings support all versions of iOS after and including iOS 5.0.

### CocoaPods

[CocoaPods](http://cocoapods.org/) is a common library dependency management tool for Objective-C.  To use the Stripe iOS bindings with CocoaPods, simply add the following to your `Podfile` and run `pod install`:

    pod 'Stripe'

Note: be sure to use the `.xcworkspace` to open your project in Xcode instead of the `.xcodeproj`.

### Copy manually

1. Clone this repository (`git clone https://github.com/stripe/stripe-ios`)
1. In the menubar, click on 'File' then 'Add files to "Project"...'
1. Select the 'Stripe' directory in your cloned stripe-ios repository (make sure not to include the stripe-ios top-level directory, you want the Stripe subfolder).
1. Make sure "Copy items into destination group's folder (if needed)" is checked"
1. Click "Add"

You will also need to add the `Security` framework to your project.

## Integration

First, you need to create a series of views to collect your users' card details. We've created a reusable component for this purpose called PaymentKit, or you can roll your own.

Note: previous versions of Stripe-iOS included PaymentKit as a dependency. We've decided to remove this dependency as of version 1.2. We've also removed the `STPView` class, which was mostly a wrapper for PaymentKit code. Separating these repositories will allow us to work on both faster. You are, of course, welcome to keep using PaymentKit in your project. If you're using any `STPView`s in your project and would like to upgrade, doing so is easy! Please see the "Migrating from versions < 1.2" section below.

### Using PaymentKit

See the README at https://github.com/stripe/PaymentKit.

### Tokenization

Once you have your card details, you'll want to package them into an STPCard object:

    STPCard *card = [STPCard new];
    card.number = myCardField.number;
    card.expMonth = myCardField.expMonth;
    card.expYear = myCardField.expYear;
    card.cvc = myCardField.cvc;

Then, send it off to Stripe:

    [Stripe createTokenWithCard:card
                 publishableKey:@"my_publishable_key"
                     completion:^(STPToken *token, NSError *error) {
                         if (error) {
                            // alert the user to the error
                         } else {
                            // use the token to create a charge (see below)
                         }
                     }];

(Replace `@"my_publishable_key"` in the above example with [your publishable key](https://manage.stripe.com/account/apikeys).)

### Using tokens

Once you've collected a token, you can send it to your server to [charge immediately](https://stripe.com/docs/api#create_charge) or [create a customer](https://stripe.com/docs/api#create_customer) to charge in the future.

These operations need to occur in your server-side code (not the iOS bindings) since these operations require [your secret key](https://manage.stripe.com/account/apikeys).

## Misc. notes

If you do not wish to send your publishableKey every time you make a call to createTokenWithCard, you can also call `[Stripe setDefaultPublishableKey:]` with your publishable key. All Stripe subsequent API requests will use this key.

### Retrieving a token

If you're implementing a complex workflow, you may want to know if you've already charged a token (since they can only be charged once).  You can do so if you have the token's ID:

    [Stripe getTokenWithId:@"token_id"
            publishableKey:@"my_publishable_key"
                completion:^(STPToken *token, NSError *error)
    {
    	if (error)
    	    NSLog(@"An error!");
    	else
    	    NSLog(@"A token for my troubles.");
    }];

### Handling errors

See [StripeError.h](https://github.com/stripe/stripe-ios/blob/master/Stripe/StripeError.h).

### Operation queues

API calls are run on `[NSOperationQueue mainQueue]` by default, but all methods have counterparts that can take a custom operation queue.

### Validation

You have a few options for handling validation of credit card data on the client, depending on what your application does.  Client-side validation of credit card data is not required since our API will correctly reject invalid card information, but can be useful to validate information as soon as a user enters it, or simply to save a network request.

The simplest thing you can do is to populate your `STPCard` object and, before sending the request, call `- (BOOL)validateCardReturningError:` on the card.  This validates the entire card object, but is not useful for validating card properties one at a time.

To validate `STPCard` properties individually, you should use the following:

     - (BOOL)validateNumber:error:
     - (BOOL)validateCvc:error:
     - (BOOL)validateExpMonth:error:
     - (BOOL)validateExpYear:error:

These methods follow the validation method convention used by [key-value validation](http://developer.apple.com/library/mac/#documentation/cocoa/conceptual/KeyValueCoding/Articles/Validation.html).  So, you can use these methods by invoking them directly, or by calling `[card validateValue:forKey:error]` for a property on the `STPCard` object.

When using these validation methods, you will want to set the property on your card object when a property does validate before validating the next property.  This allows the methods to use existing properties on the card correctly to validate a new property.  For example, validating `5` for the `expMonth` property will return YES if no `expYear` is set.  But if `expYear` is set and you try to set `expMonth` to 5 and the combination of `expMonth` and `expYear` is in the past, `5` will not validate.  The order in which you call the validate methods does not matter for this though.

## Example app

The example app is a great way to see the flow of recording credit card details, converting them to a token with the Stripe iOS bindings, and then using that token to charge users on your backend. It uses [PaymentKit](https://github.com/stripe/PaymentKit) to create a simple credit card form, and a small backend hosted with Parse Cloud Code to process the actual transactions.

### Running the example

Before you can run the app, you need to provide it with your own Stripe and Parse API keys.

#### Stripe
1. If you haven't already, sign up for a [Stripe account](https://dashboard.stripe.com/register) (it takes seconds). Then go to https://dashboard.stripe.com/account/apikeys.
2. Replace the `StripePublishableKey` constant in Example/StripeExample/Constants.m with your Test Publishable Key.
3. Replace the `stripe_secret_key` variable in Example/Parse/cloud/main.js with your Test Secret Key.

#### Parse
1. Sign up for a [Parse account](https://parse.com/#signup), then create a new Parse app.
2. Head to the "Application keys" section of your parse app's settings page. Replace the `ParseApplicationId` and `ParseClientKey` constants in Example/StripeExample/Constants.m with your app's Application ID and Client Key, respectively.
3. Replace the appropriate values in Example/Parse/config/global.json with your Parse app's name, Application ID, and Master Secret. IMPORTANT: these values, along with your Stripe Secret Key, can be used to control your Stripe and Parse accounts. Thus, once you edit these files, you shoudn't check them back into git.
4. Install the Parse command line tool at https://www.parse.com/docs/cloud_code_guide#started, then run `parse deploy` from the Example/Parse directory.

After this is done, you can make test payments through the app (use credit card number 4242 4242 4242 4242, along with any cvc and any future expiration date) and then view them in your Stripe Dashboard!

## Running the tests

1. Open Stripe.xcodeproj
1. Select either the iOS or OS X scheme in the toolbar at the top
1. Go to Product->Test

## Migrating from versions < 1.2

As mentioned above, versions of Stripe-iOS prior to 1.2 included a class called `STPView`, which provided a pre-built credit card form. This functionality has been moved from Stripe-iOS to PaymentKit, a separate project. If you were using `STPView` prior to version 1.2, migrating is simple:

1. Add PaymentKit to your project, as explained on its [project page](https://github.com/stripe/PaymentKit).
2. Replace any references to `STPView` with a `PKView` instead. Similarly, any classes that implement `STPViewDelegate` should now instead implement the equivalent `PKViewDelegate` methods. Note that unlike `STPView`, `PKView` does not take a Stripe API key in its constructor.
3. To submit the credit card details from your `PKView` instance, where you would previously call `createToken` on your `STPView`, replace that with the following code (assuming `self.paymentView` is your `PKView` instance):

        if (![self.paymentView isValid]) {
            return;
        }
        STPCard *card = [[STPCard alloc] init];
        card.number = self.paymentView.card.number;
        card.expMonth = self.paymentView.card.expMonth;
        card.expYear = self.paymentView.card.expYear;
        card.cvc = self.paymentView.card.cvc;
        [Stripe createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
            if (error) {
                // handle the error as you did previously
            } else {
                // submit the token to your payment backend as you did previously
            }
        }];
