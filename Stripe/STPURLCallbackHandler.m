//
//  STPURLCallbackHandler.m
//  Stripe
//
//  Created by Brian Dorfman on 10/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPURLCallbackHandler.h"

#import "STPAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@implementation Stripe (STPURLCallbackHandlerAdditions)

+ (BOOL)handleStripeURLCallbackWithURL:(NSURL *)url {
    if (url) {
        return [[STPURLCallbackHandler shared] handleURLCallback:url];
    }
    else {
        return NO;
    }
}

@end

@interface STPURLCallback : NSObject
@property (nonatomic) NSURLComponents *urlComponents;
@property (nonatomic) id<STPURLCallbackListener> listener;
@end

@interface STPURLCallbackHandler ()
@property (nonatomic) NSArray <STPURLCallback *> *callbacks;
@end

@implementation STPURLCallbackHandler

+ (instancetype)shared {
    static STPURLCallbackHandler *handler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [STPURLCallbackHandler new];
    });

    return handler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.callbacks = [NSArray new];
    }
    return self;
}

- (BOOL)urlComponent:(NSURLComponents *)lhsComponents matchesURL:(NSURLComponents *)rhsComponents {
    // TODO: Compare query items?
    return ([lhsComponents.scheme isEqualToString:rhsComponents.scheme]
            && [lhsComponents.host isEqualToString:rhsComponents.host]
            && [lhsComponents.path isEqualToString:rhsComponents.path]);
}

- (BOOL)handleURLCallback:(NSURL *)url {

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url
                                               resolvingAgainstBaseURL:NO];

    BOOL resultsOrred = NO;

    for (STPURLCallback *callback in self.callbacks) {
        if ([self urlComponent:callback.urlComponents matchesURL:components]) {

            resultsOrred |= [callback.listener handleURLCallback:url];
        }
    }

    return resultsOrred;
}

- (void)registerListener:(id<STPURLCallbackListener>)listener
                  forURL:(NSURL *)url {

    STPURLCallback *callback = [STPURLCallback new];
    callback.listener = listener;
    callback.urlComponents = [[NSURLComponents alloc] initWithURL:url
                                          resolvingAgainstBaseURL:NO];

    if (callback.listener && callback.urlComponents) {
        NSMutableArray <STPURLCallback *> *callbacksCopy = self.callbacks.mutableCopy;
        [callbacksCopy addObject:callback];
        self.callbacks = callbacksCopy.copy;
    }
}

- (void)unregisterListener:(id<STPURLCallbackListener>)listener
                    forURL:(NSURL *)url {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url
                                               resolvingAgainstBaseURL:NO];

    NSMutableArray *callbacksToRemove = [NSMutableArray new];

    for (STPURLCallback *callback in self.callbacks) {
        if ([self urlComponent:callback.urlComponents matchesURL:components]
            && listener == callback.listener) {
            [callbacksToRemove addObject:callback];
        }
    }
    NSMutableArray <STPURLCallback *> *callbacksCopy = self.callbacks.mutableCopy;
    [callbacksCopy removeObjectsInArray:callbacksToRemove];
    self.callbacks = callbacksCopy.copy;

}

@end

NS_ASSUME_NONNULL_END
