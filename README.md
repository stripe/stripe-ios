# Stripe iOS Bindings

The Stripe iOS bindings make it easy to collect your users' credit card details inside your iOS app. By creating [tokens](https://stripe.com/docs/api#tokens), Stripe handles the bulk of PCI compliance by preventing sensitive card data from hitting your server (for more, see [our article about PCI compliance](https://support.stripe.com/questions/do-i-need-to-be-pci-compliant-what-do-i-have-to-do)).

To get started, see our [tutorial](https://stripe.com/docs/mobile/ios).

## Installation

There are two ways to add Stripe to your project:

### CocoaPods

[CocoaPods](http://cocoapods.org/) is a common library dependency management tool for Objective-C.  To use the Stripe iOS bindings with CocoaPods, simply add the following to your `Podfile` and run `pod install`:

    pod 'Stripe', :git => 'https://github.com/stripe/stripe-ios.git'

Note: be sure to use the `.xcworkspace` to open your project in Xcode instead of the `.xcproject`. You will also need to add the `QuartzCore` framework to your project.

### Copy manually

1. Clone this repository (`git clone --recursive`)
1. In the menubar, click on 'File' then 'Add files to "Project"...'
1. Select the 'Stripe' directory in your cloned stripe-ios repository
1. Make sure "Copy items into destination group's folder (if needed)" is checked"
1. Click "Add"

You will also need to add the `QuartzCore` framework to your project.

## Example app

You can also clone this repository to see our example app, TreatCar. To do so, just clone this repository, then initialize submodules:
    
    git submodule update --init --recursive
    
Then, simply open Stripe.xcodeproj in Xcode and run TreatCar.

## Integration

First, you need to create a view to collect your users' card details. We've created the `STPView` class which does this all for you, or you can create a custom view of your own.

### Using STPView

![PaymentKit](https://stripe.com/img/documentation/ios/PaymentKit.png)

Create and show a `STPView`:

    STPView *cardView = [[STPView alloc] initWithFrame:CGRectMake(15,20,290,55) andKey:@"my_publishable_key"];
    [self.view addSubview:cardView];

To receive feedback about the state of the view:

    cardView.delegate = self // implement STPViewDelegate
    
    ...
    
    - (void)stripeView:(STPView *)view withCard:(PKCard *)card isValid:(BOOL)valid
    {
        // Enable the "save" button only if the card form is complete.
        self.navigationItem.rightBarButtonItem.enabled = valid;
    }

Finally, submit the details to Stripe to receive a [token](https://stripe.com/docs/api#tokens):

    [cardView createToken:^(STPToken *token, NSError *error) {
        if (error) {
            [self hasError:error];
        } else {
            [self hasToken:token]; // Hooray!
        }
    }];
    
(Replace `@"my_publishable_key"` with [your publishable key](https://manage.stripe.com/account/apikeys).)
    
### Using your own view

After showing your view, create and populate a `STPCard` with the details you collected:

    STPCard *card = [[STPCard alloc] init];
    card.number = @"4242424242424242";
    card.expMonth = 12;
    card.expYear = 2020;

Then send it to Stripe:

    [Stripe createTokenWithCard:card
                 publishableKey:@"my_publishable_key"
                     completion:^(STPToken *token, NSError *error) {
                         if (error) {
                             [self hasError:error];
                         } else {
                             [self hasToken:token]; // Hooray!
                         }
                     }];

(Replace `@"my_publishable_key"` with [your publishable key](https://manage.stripe.com/account/apikeys).)

## Using tokens

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

Expected errors, such as a card being invalid, generate `NSError` objects.  The bindings will return errors that are in the `StripeDomain` domain and have a `code` of `STPInvalidRequestError`, `STPAPIError`, or `STPCardError` -- these match up to the `type` property of [errors returned by the Stripe API](https://stripe.com/docs/api#errors).  Additionally, as recommended by Cocoa guidelines, all errors in the `StripeDomain` also provide a localizable user-facing error message that can be retrieved by calling `[error localizedDescription]`.

The `userInfo` dictionary of errors in the `StripeDomain` contains a developer-facing error message corresponding to the `message` property returned by the [Stripe API for an error](https://stripe.com/docs/api#errors), and, when applicable, a card error code corresponding to the `code` property and a parameter the error is for corresponding to the `param` property.  These are the values for the keys `STPErrorMessageKey`, `STPCardErrorCodeKey`, and `STPErrorParameterKey` in the `userInfo` dictionary, respectively.  Note that the values for `STPErrorParameterKey` will be camel cased and match up to the properties on `STPCard`.  For example, an invalid expiration month will have `expMonth`, not `exp_month`, as the value for `STPErrorParameterKey` in the `userInfo` dictionary).

Almost all calls made to methods in the Stripe iOS bindings return nothing but errors in the `StripeDomain`.  The only exception to this is calls to `createTokenWithCard` and `getTokenWithId`.  Both of these methods make requests using `NSURLConnection`, so if the request fails to even be made, these calls just return the error object that is generated and returned by `NSURLConnection` (which will be in the `NSURLErrorDomain`).

### Operation queues

When you are writing an iOS application, it is important to keep the main thread responsive even if your application performs a time-consuming task.  In most cases, you should be able to use the default `createToken` and `getToken` methods for creating and retrieving tokens, which will run your `completionHandler` block on `[NSOperationQueue mainQueue]`.  However, if you have a more complicated application and want to control where your `completionHandler` gets run, you can also pass in a queue as a parameter to both of these calls.  See:

	+ (void)createTokenWithCard:publishableKey:operationQueue:completionHandler
	+ (void)getTokenWithId:publishableKey:operationQueue:completionHandler

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
