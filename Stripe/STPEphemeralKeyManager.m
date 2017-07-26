//
//  STPEphemeralKeyManager.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPEphemeralKeyManager.h"

#import "StripeError+Private.h"
#import "STPCustomerContext.h"
#import "STPEphemeralKey.h"
#import "STPPromise.h"

static NSTimeInterval const DefaultExpirationInterval = 60;
static NSTimeInterval const MinEagerRefreshInterval = 60*60;

@interface STPEphemeralKeyManager ()
@property (nonatomic) STPEphemeralKey *customerKey;
@property (nonatomic) NSString *apiVersion;
@property (nonatomic, weak) id<STPEphemeralKeyProvider> keyProvider;
@property (nonatomic) NSDate *lastEagerKeyRefresh;
@property (nonatomic) STPPromise<STPEphemeralKey *>*createKeyPromise;
@end

@implementation STPEphemeralKeyManager

- (instancetype)initWithKeyProvider:(id<STPEphemeralKeyProvider>)keyProvider apiVersion:(NSString *)apiVersion {
    self = [super init];
    if (self) {
        _expirationInterval = DefaultExpirationInterval;
        _keyProvider = keyProvider;
        _apiVersion = apiVersion;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleWillForegroundNotification)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)setExpirationInterval:(NSTimeInterval)expirationInterval {
    _expirationInterval = MIN(expirationInterval, 60*60);
}

- (BOOL)currentKeyIsUnexpired {
    return self.customerKey && self.customerKey.expires.timeIntervalSinceNow > self.expirationInterval;
}

- (BOOL)shouldPerformEagerRefresh {
    return !self.lastEagerKeyRefresh || self.lastEagerKeyRefresh.timeIntervalSinceNow > MinEagerRefreshInterval;
}

- (void)handleWillForegroundNotification {
    // To make sure we don't end up hitting the ephemeral keys endpoint on every
    // foreground (e.g. if there's an issue decoding the ephemeral key), throttle
    // eager refreshses to once per hour.
    if (!self.currentKeyIsUnexpired && self.shouldPerformEagerRefresh) {
        self.lastEagerKeyRefresh = [NSDate date];
        [self.keyProvider createCustomerKeyWithAPIVersion:self.apiVersion completion:^(NSDictionary *jsonResponse, __unused NSError *error) {
            STPEphemeralKey *key = [STPEphemeralKey decodedObjectFromAPIResponse:jsonResponse];
            if (key) {
                self.customerKey = key;
            }
        }];
    }
}

- (void)getCustomerKey:(STPEphemeralKeyCompletionBlock)completion {
    if (self.currentKeyIsUnexpired) {
        completion(self.customerKey, nil);
    } else {
        if (self.createKeyPromise) {
            // coalesce repeated calls into one request
            [[self.createKeyPromise onSuccess:^(STPEphemeralKey *key) {
                completion(key, nil);
            }] onFailure:^(NSError *error) {
                completion(nil, error);
            }];
        } else {
            self.createKeyPromise = [[[STPPromise<STPEphemeralKey *> new] onSuccess:^(STPEphemeralKey *key) {
                self.customerKey = key;
                completion(key, nil);
            }] onFailure:^(NSError *error) {
                completion(nil, error);
            }];
            [self.keyProvider createCustomerKeyWithAPIVersion:self.apiVersion completion:^(NSDictionary *jsonResponse, NSError *error) {
                STPEphemeralKey *key = [STPEphemeralKey decodedObjectFromAPIResponse:jsonResponse];
                if (key) {
                    [self.createKeyPromise succeed:key];
                } else {
                    // the API request failed
                    if (error) {
                        [self.createKeyPromise fail:error];
                    }
                    // the ephemeral key could not be decoded
                    else {
                        [self.createKeyPromise fail:[NSError stp_ephemeralKeyDecodingError]];
                        NSAssert(NO, @"Could not parse the ephemeral key response. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app. For more info, see https://stripe.com/docs/mobile/ios/standard#prepare-your-api");
                    }
                }
                self.createKeyPromise = nil;
            }];
        }
    }
}

@end
