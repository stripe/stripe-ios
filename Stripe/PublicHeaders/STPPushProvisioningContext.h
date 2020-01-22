//
//  STPPushProvisioningContext.h
//  Stripe
//
//  Created by Jack Flintermann on 9/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>
#import "STPEphemeralKeyProvider.h"
#import "STPCard.h"

@class STPAPIClient;

NS_ASSUME_NONNULL_BEGIN

/**
 This class makes it easier to implement "Push Provisioning", the process by which an end-user can add a card to their Apple Pay wallet without having to type their number. This process is mediated by an Apple class called `PKAddPaymentPassViewController`; this class will help you implement that class' delegate methods. Note that this flow requires a special entitlement from Apple; for more information please see https://stripe.com/docs/issuing/cards/digital-wallets .
 */
@interface STPPushProvisioningContext : NSObject

/**
 The API Client to use to make requests.
 
 Defaults to [STPAPIClient sharedClient]
 */
@property (nonatomic, strong) STPAPIClient *apiClient;

/**
 This is a helper method to generate a PKAddPaymentPassRequestConfiguration that will work with
 Stripe's Issuing APIs. Pass the returned configuration object to `PKAddPaymentPassViewController`'s `initWithRequestConfiguration:delegate:` initializer.
 
 @param name Your cardholder's name. Example: John Appleseed
 @param description A localized description of your card's name. This will appear in Apple's UI as "{description} will be available in Wallet". Example: Platinum Rewards Card
 @param last4 The last 4 of the card to be added to the user's Apple Pay wallet. Example: 4242
 @param brand The brand of the card. Example: `STPCardBrandVisa`
 */
+ (PKAddPaymentPassRequestConfiguration *)requestConfigurationWithName:(NSString *)name
                                                           description:(nullable NSString *)description
                                                                 last4:(nullable NSString *)last4
                                                                 brand:(STPCardBrand)brand;

/**
  In order to retreive the encrypted payload that PKAddPaymentPassViewController expects, the Stripe SDK must talk to the Stripe API. As this requires privileged access, you must write a "key provider" that generates an Ephemeral Key on your backend and provides it to the SDK when requested. For more information, see https://stripe.com/docs/mobile/ios/basic#ephemeral-key
 */
- (instancetype)initWithKeyProvider:(id<STPIssuingCardEphemeralKeyProvider>)keyProvider;

/**
 This method lines up with the method of the same name on `PKAddPaymentPassViewControllerDelegate`. You should implement that protocol in your own app, and when that method is called, call this method on your `STPPushProvisioningContext`. This in turn will first initiate a call to your `keyProvider` (see above) to obtain an Ephemeral Key, then make a call to the Stripe Issuing API to fetch an encrypted payload for the card in question, then return that payload to iOS.
 */
- (void)addPaymentPassViewController:(PKAddPaymentPassViewController *)controller
 generateRequestWithCertificateChain:(NSArray<NSData *> *)certificates
                               nonce:(NSData *)nonce
                      nonceSignature:(NSData *)nonceSignature
                   completionHandler:(void (^)(PKAddPaymentPassRequest *))handler;
@end

NS_ASSUME_NONNULL_END
