//
//  STPURLCallbackHandler.m
//  Stripe
//
//  Created by Brian Dorfman on 10/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPURLCallbackHandler.h"

#import "STPAPIClient.h"

#import "NSURLComponents+Stripe.h"


#define FAUXPAS_IGNORED_ON_LINE(...)
NS_ASSUME_NONNULL_BEGIN

@implementation Stripe (STPURLCallbackHandlerAdditions)


+ (BOOL)handleStripeURLCallbackWithURL:(NSURL *)url FAUXPAS_IGNORED_ON_LINE(UnusedMethod) {
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

@implementation STPURLCallback
@end

@interface STPURLCallbackHandler ()
@property (nonatomic) NSArray <STPURLCallback *> *callbacks;
@end

@implementation STPURLCallbackHandler

+ (instancetype)shared {
    static STPURLCallbackHandler *handler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [self new];
    });

    return handler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _callbacks = [NSArray new];
    }
    return self;
}

- (BOOL)handleURLCallback:(NSURL *)url {

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url
                                               resolvingAgainstBaseURL:NO];

    BOOL resultsOrred = NO;

    for (STPURLCallback *callback in self.callbacks) {
        if ([callback.urlComponents stp_matchesURLComponents:components]) {
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

- (void)unregisterListener:(id<STPURLCallbackListener>)listener {
    NSMutableArray *callbacksToRemove = [NSMutableArray new];

    for (STPURLCallback *callback in self.callbacks) {
        if (listener == callback.listener) {
            [callbacksToRemove addObject:callback];
        }
    }
    NSMutableArray <STPURLCallback *> *callbacksCopy = self.callbacks.mutableCopy;
    [callbacksCopy removeObjectsInArray:callbacksToRemove];
    self.callbacks = callbacksCopy.copy;
}

@end

NS_ASSUME_NONNULL_END
