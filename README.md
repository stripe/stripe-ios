# Stripe iOS Bindings

The Stripe iOS bindings can be used to generate [tokens](https://stripe.com/docs/api#tokens) in your iOS application.  If you are building an iOS application that charges a credit card, you should use these bindings to make sure you don't pass credit card information to your server (and, so, are PCI compliant).

## Installation

1. Clone this repository
1. In the menubar, click on 'File' then 'Add files to "Project"...'
1. Select all the files in the 'src' directory of your cloned stripe-ios repository
1. Make sure "Copy items into destination group's folder (if needed)" is checked"
1. Click "Add"

## Guide

There are three main classes in the Stripe iOS bindings that you should care about.  `STPCard` is a representation of a credit card.  You will need to create and populate this object with the credit card details a customer enters.  `STPToken` is a representation of the token Stripe returns for a credit card.  You can't construct these yourself, but will need to create them (shown below).  `Stripe` is a static class that you use to interact with the Stripe REST API.

Also, there are a lot of comments in the code itself.  Look through the .h files for a more thorough understanding of this library.

### Creating a token

    STPCard *card = [[STPCard alloc] init];
    card.number = @"4242424242424242";
    card.expMonth = 12;
    card.expYear = 2020;

    STPSuccessBlock successHandler = ^(STPToken *token)
    {
        NSSLog(@"Oh the sweet silence of success! Now I
        should send my data along with this token to my
        server, where I can use the token to charge the
        card or create a Stripe customer.");
    };

    STPErrorBlock errorHandler = ^(NSError *error)
    {
        NSLog(@"Error trying to create token %@", [error
        localizedDescription]);
    }

    [Stripe createTokenWithCard:card
                 publishableKey:@"my_publishable_key"
                        success:successHandler
                          error:errorHandler];

Note that if you do not wish to send your publishableKey every time you make a call to createTokenWithCard, you can also call `[Stripe setDefaultPublishableKey:]` with your publishable key, and all Stripe API requests will use this key.

### Retrieving a token

If you're implementing a complex workflow, you may want to know if you've already charged a token (since they can only be charged once).  You can do so if you have the token's ID:

    [Stripe getTokenWithId:@"token_id" publishableKey:@"my_publishable_key"
    completionHandler:^(STPToken *token, NSError *error)
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

## iOS Example

Run the "TreatCar" target.  This is a simple application that lets you order treat cars from an iOS device.

## OS X Support

OS X support is not yet well tested (though all the tests do run).  Feel free to give it a try and let us know of any problems you run into!