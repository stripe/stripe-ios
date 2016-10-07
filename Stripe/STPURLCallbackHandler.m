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

@interface STPURLCallbackHandler ()
@property (nonatomic) NSDictionary <NSString *, NSArray <id<STPURLCallbackListener>> *> *listenerMap; 
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
        self.listenerMap = [NSDictionary new];
    }
    return self;
}

- (BOOL)handleURLCallback:(NSURL *)url {
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url
                                               resolvingAgainstBaseURL:NO];
    components.query = nil;
    
    NSString *urlString = components.string;
    if (urlString) {
        NSArray <id<STPURLCallbackListener>> *listeners = self.listenerMap[urlString];
        BOOL resultsOrred = NO;
        for (id<STPURLCallbackListener> listener in listeners) {
            resultsOrred |= [listener handleURLCallback:url];
        }
        
        return resultsOrred;
    }
    
    return NO;
}

- (void)registerListener:(id<STPURLCallbackListener>)listener
                  forURL:(NSURL *)url {
    NSMutableDictionary <NSString *, NSArray <id<STPURLCallbackListener>> *> *listenerMapCopy = self.listenerMap.mutableCopy;
    NSString *urlString = url.absoluteString;
    if (urlString) {
        NSMutableArray <id<STPURLCallbackListener>> *listeners = self.listenerMap[urlString].mutableCopy ?: [NSMutableArray new];
        [listeners addObject:listener];
        listenerMapCopy[urlString] = listeners.copy;
        self.listenerMap = listenerMapCopy.copy;
    }
}

- (void)unregisterListener:(id<STPURLCallbackListener>)listener
                    forURL:(NSURL *)url {
    NSMutableDictionary <NSString *, NSArray <id<STPURLCallbackListener>> *> *listenerMapCopy = self.listenerMap.mutableCopy;
    NSString *urlString = url.absoluteString;
    if (urlString) {
        NSMutableArray <id<STPURLCallbackListener>> *listeners = self.listenerMap[urlString].mutableCopy;
        [listeners removeObject:listener];
        listenerMapCopy[urlString] = listeners.copy;
        self.listenerMap = listenerMapCopy.copy;
    }
}

@end

NS_ASSUME_NONNULL_END
