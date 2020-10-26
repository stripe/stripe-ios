//
//  STPAPIClient+PinManagement.m
//  Stripe
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPinManagementService.h"
#import "STPAPIRequest.h"
#import "STPIssuingCardPin.h"
#import "STPEphemeralKeyManager.h"
#import "STPAPIClient+Private.h"

@interface STPPinManagementService()
@property (nonatomic, strong) STPEphemeralKeyManager *keyManager;
@end

@implementation STPPinManagementService

- (instancetype)initWithKeyProvider:(id<STPIssuingCardEphemeralKeyProvider>)keyProvider {
    self = [super init];
    if (self) {
        _apiClient = [STPAPIClient sharedClient];
        _keyManager = [[STPEphemeralKeyManager alloc] initWithKeyProvider:keyProvider apiVersion:[STPAPIClient apiVersion] performsEagerFetching:NO];
    }
    return self;
}

- (void)retrievePin:(NSString *) cardId
         verificationId:(NSString *) verificationId
        oneTimeCode:(NSString *) oneTimeCode
         completion:(STPPinCompletionBlock) completion{
    NSString *endpoint = [NSString stringWithFormat:@"issuing/cards/%@/pin", cardId];
    NSDictionary *parameters = @{
                                 @"verification": @{
                                         @"id": verificationId,
                                         @"one_time_code": oneTimeCode,
                                         },
                                 };
    [self.keyManager getOrCreateKey:^(STPEphemeralKey * _Nullable ephemeralKey, NSError * _Nullable keyError) {
        if (ephemeralKey == nil) {
            completion(nil, STPPinEphemeralKeyError, keyError);
            return;
        }

        [STPAPIRequest<STPIssuingCardPin *> getWithAPIClient:self.apiClient
                                                    endpoint:endpoint
                                           additionalHeaders:[self.apiClient authorizationHeaderUsingEphemeralKey:ephemeralKey]
                                                  parameters:parameters
                                                deserializer:[STPIssuingCardPin new]
                                                  completion:^(
                                                               STPIssuingCardPin *details,
                                                               __unused     NSHTTPURLResponse *response,
                                                               NSError *error) {
                                                      // Find if there were errors
                                                      if (details.error != nil) {
                                                          NSString* code = details.error[@"code"];
                                                          if ([@"api_key_expired" isEqualToString:code]) {
                                                              completion(nil, STPPinEphemeralKeyError, error);
                                                          } else if ([@"expired" isEqualToString:code]) {
                                                              completion(nil, STPPinErrorVerificationExpired, nil);
                                                          } else if ([@"incorrect_code" isEqualToString:code]) {
                                                              completion(nil, STPPinErrorVerificationCodeIncorrect, nil);
                                                          } else if ([@"too_many_attempts" isEqualToString:code]) {
                                                              completion(nil, STPPinErrorVerificationTooManyAttempts, nil);
                                                          } else if ([@"already_redeemed" isEqualToString:code]) {
                                                              completion(nil, STPPinErrorVerificationAlreadyRedeemed, nil);
                                                          } else {
                                                              completion(nil, STPPinUnknownError, error);
                                                          }
                                                          return;
                                                      }
                                                      completion(details, STPPinSuccess, nil);
                                                  }];
    }];
}

- (void)updatePin:(NSString *) cardId
           newPin:(NSString *) newPin
     verificationId:(NSString *) verificationId
        oneTimeCode:(NSString *) oneTimeCode
         completion:(STPPinCompletionBlock) completion{
    NSString *endpoint = [NSString stringWithFormat:@"issuing/cards/%@/pin", cardId];
    NSDictionary *parameters = @{
                                 @"verification": @{
                                         @"id": verificationId,
                                         @"one_time_code": oneTimeCode,
                                         },
                                 @"pin": newPin,
                                 };
    [self.keyManager getOrCreateKey:^(STPEphemeralKey * _Nullable ephemeralKey, NSError * _Nullable keyError) {
        if (ephemeralKey == nil) {
            completion(nil, STPPinEphemeralKeyError, keyError);
            return;
        }
        [STPAPIRequest<STPIssuingCardPin *> postWithAPIClient:self.apiClient
                                                     endpoint:endpoint
                                            additionalHeaders:[self.apiClient authorizationHeaderUsingEphemeralKey:ephemeralKey]
                                                  parameters:parameters
                                                deserializer:[STPIssuingCardPin new]
                                                  completion:^(
                                                               STPIssuingCardPin *details,
                                                               __unused     NSHTTPURLResponse *response,
                                                               NSError *error) {
                                                      // Find if there were errors
                                                      if (details.error != nil) {
                                                          NSString* code = details.error[@"code"];
                                                          if ([@"api_key_expired" isEqualToString:code]) {
                                                              completion(nil, STPPinEphemeralKeyError, error);
                                                          } else if ([@"expired" isEqualToString:code]) {
                                                              completion(nil, STPPinErrorVerificationExpired, nil);
                                                          } else if ([@"incorrect_code" isEqualToString:code]) {
                                                              completion(nil, STPPinErrorVerificationCodeIncorrect, nil);
                                                          } else if ([@"too_many_attempts" isEqualToString:code]) {
                                                              completion(nil, STPPinErrorVerificationTooManyAttempts, nil);
                                                          } else if ([@"already_redeemed" isEqualToString:code]) {
                                                              completion(nil, STPPinErrorVerificationAlreadyRedeemed, nil);
                                                          } else {
                                                              completion(nil, STPPinUnknownError, error);
                                                          }
                                                          return;
                                                      }
                                                      completion(details, STPPinSuccess, nil);
                                                  }];
    }];
}

@end
