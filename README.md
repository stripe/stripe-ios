# Stripe iOS Bindings

The Stripe iOS bindings make it easy to collect your users' credit card details inside your iOS app. By creating [tokens](https://stripe.com/docs/api#tokens), Stripe handles the bulk of PCI compliance by preventing sensitive card data from hitting your server (for more, see [our article about PCI compliance](https://support.stripe.com/questions/do-i-need-to-be-pci-compliant-what-do-i-have-to-do)).

To get started, see our [tutorial](https://stripe.com/docs/mobile/ios).

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

## Example app

For a simple, annotated demonstration of how to use the Stripe bindings to obtain and charge a Stripe token, consult PaymentViewController in the StripeExample folder or run the StripeExample app.

## Integration

First, you need to create a series of views to collect your users' card details. We've created a reusable component for this purpose called PaymentKit, or you can roll your own.

### Using PaymentKit

See the README at (https://github.com/stripe/PaymentKit).

Note: Version 1.2 of this libary removes the STPView class. PaymentKit provides a near-identical version of this called PKView if you need to migrate.

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

## Running the tests

1. Open Stripe.xcodeproj
1. Select either the iOS or OS X scheme in the toolbar at the top
1. Go to Product->Test

## OS X Support

OS X support is not yet well tested (though all the tests do run).  Feel free to give it a try and let us know of any problems you run into!
