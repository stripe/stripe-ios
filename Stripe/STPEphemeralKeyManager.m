//
//  STPEphemeralKeyManager.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPEphemeralKeyManager.h"

#import "NSError+Stripe.h"
#import "STPEphemeralKey.h"
#import "STPPromise.h"

static NSTimeInterval const DefaultExpirationInterval = 60;
static NSTimeInterval const MinEagerRefreshInterval = 60*60;

@interface STPEphemeralKeyManager ()
@property (nonatomic) STPEphemeralKey *ephemeralKey;
@property (nonatomic) NSString *apiVersion;
@property (nonatomic) id keyProvider;
@property (nonatomic, readwrite, assign) BOOL performsEagerFetching;
@property (nonatomic) NSDate *lastEagerKeyRefresh;
@property (nonatomic) STPPromise<STPEphemeralKey *>*createKeyPromise;
@end

@implementation STPEphemeralKeyManager

- (instancetype)initWithKeyProvider:(id)keyProvider
                         apiVersion:(NSString *)apiVersion
              performsEagerFetching:(BOOL)performsEagerFetching {
    self = [super init];
    if (self) {
        NSAssert([keyProvider conformsToProtocol:@protocol(STPCustomerEphemeralKeyProvider)] || [keyProvider conformsToProtocol:@protocol(STPIssuingCardEphemeralKeyProvider)], @"Your STPEphemeralKeyProvider must either implement `STPCustomerEphemeralKeyProvider` or `STPIssuingCardEphemeralKeyProvider`.");
        _expirationInterval = DefaultExpirationInterval;
        _keyProvider = keyProvider;
        _apiVersion = apiVersion;
        _performsEagerFetching = performsEagerFetching;
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
    return self.ephemeralKey && self.ephemeralKey.expires.timeIntervalSinceNow > self.expirationInterval;
}

- (BOOL)shouldPerformEagerRefresh {
    return self.performsEagerFetching && (!self.lastEagerKeyRefresh || self.lastEagerKeyRefresh.timeIntervalSinceNow > MinEagerRefreshInterval);
}

- (void)handleWillForegroundNotification {
    // To make sure we don't end up hitting the ephemeral keys endpoint on every
    // foreground (e.g. if there's an issue decoding the ephemeral key), throttle
    // eager refreshes to once per hour.
    if (!self.currentKeyIsUnexpired && self.shouldPerformEagerRefresh) {
        self.lastEagerKeyRefresh = [NSDate date];
        [self getOrCreateKey:^(__unused STPEphemeralKey * _Nullable ephemeralKey, __unused NSError * _Nullable error) {
            // getOrCreateKey sets the self.ephemeralKey. Nothing left to do for us here
        }];
    }
}

- (void)_createKey {
    STPJSONResponseCompletionBlock jsonCompletion = ^(NSDictionary *jsonResponse, NSError *error) {
        STPEphemeralKey *key = [STPEphemeralKey decodedObjectFromAPIResponse:jsonResponse];
        if (key) {
            [self.createKeyPromise succeed:key];
        } else {
            // the API request failed
            if (error) {
                [self.createKeyPromise fail:error];
            } else {
                // the ephemeral key could not be decoded
                [self.createKeyPromise fail:[NSError stp_ephemeralKeyDecodingError]];
                if ([self.keyProvider conformsToProtocol:@protocol(STPCustomerEphemeralKeyProvider)]) {
                    NSAssert(NO, @"Could not parse the ephemeral key response following protocol STPCustomerEphemeralKeyProvider. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app. For more info, see https://stripe.com/docs/mobile/ios/standard#prepare-your-api");
                } else if ([self.keyProvider conformsToProtocol:@protocol(STPIssuingCardEphemeralKeyProvider)]) {
                    NSAssert(NO, @"Could not parse the ephemeral key response following protocol STPCustomerEphemeralKeyProvider. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app. For more info, see https://stripe.com/docs/mobile/ios/standard#prepare-your-api");
                }
                NSAssert(NO, @"Could not parse the ephemeral key response. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app. For more info, see https://stripe.com/docs/mobile/ios/standard#prepare-your-api");
            }
        }
        self.createKeyPromise = nil;
    };
    
    if ([self.keyProvider conformsToProtocol:@protocol(STPCustomerEphemeralKeyProvider)]) {
        id<STPCustomerEphemeralKeyProvider> provider = self.keyProvider;
        [provider createCustomerKeyWithAPIVersion:self.apiVersion completion:jsonCompletion];
    } else if ([self.keyProvider conformsToProtocol:@protocol(STPIssuingCardEphemeralKeyProvider)]) {
        id<STPIssuingCardEphemeralKeyProvider> provider = self.keyProvider;
        [provider createIssuingCardKeyWithAPIVersion:self.apiVersion completion:jsonCompletion];
    }
}

- (void)getOrCreateKey:(STPEphemeralKeyCompletionBlock)completion {
    if (self.currentKeyIsUnexpired) {
        completion(self.ephemeralKey, nil);
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
                self.ephemeralKey = key;
                completion(key, nil);
            }] onFailure:^(NSError *error) {
                completion(nil, error);
            }];
            [self _createKey];
        }
    }
}

@end
