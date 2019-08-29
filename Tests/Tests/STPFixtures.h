//
//  STPFixtures.h
//  Stripe
//
//  Created by Ben Guo on 3/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <PassKit/PassKit.h>
#import <Stripe/Stripe.h>

extern NSString *const STPTestJSONCustomer;

extern NSString *const STPTestJSONCard;

extern NSString *const STPTestJSONPaymentIntent;
extern NSString *const STPTestJSONSetupIntent;
extern NSString *const STPTestJSONPaymentMethod;
extern NSString *const STPTestJSONApplePayPaymentMethod;

extern NSString *const STPTestJSONSource3DS;
extern NSString *const STPTestJSONSourceAlipay;
extern NSString *const STPTestJSONSourceBancontact;
extern NSString *const STPTestJSONSourceCard;
extern NSString *const STPTestJSONSourceEPS;
extern NSString *const STPTestJSONSourceGiropay;
extern NSString *const STPTestJSONSourceiDEAL;
extern NSString *const STPTestJSONSourceMultibanco;
extern NSString *const STPTestJSONSourceP24;
extern NSString *const STPTestJSONSourceSEPADebit;
extern NSString *const STPTestJSONSourceSOFORT;

@interface STPFixtures : NSObject

/**
 An STPConnectAccountParams object with all of the fields filled in, and
 ToS accepted.
 */
+ (STPConnectAccountParams *)accountParams;

/**
 An Address object with all fields filled.
 */
+ (STPAddress *)address;

/**
 A PKPaymentObject with test payment data.
 */
+ (PKPayment *)applePayPayment;

/**
 A BankAccountParams object with all fields filled.
 */
+ (STPBankAccountParams *)bankAccountParams;

/**
 A CardParams object with a valid number, expMonth, expYear, and cvc.
 */
+ (STPCardParams *)cardParams;

/**
 A valid card object
 */
+ (STPCard *)card;

/**
 A Source object with type card
 */
+ (STPSource *)cardSource;

/**
 A Token for a card
 */
+ (STPToken *)cardToken;

/**
 A Customer object with an empty sources array.
 */
+ (STPCustomer *)customerWithNoSources;

/**
 A Customer object with a single card token in its sources array, and
 default_source set to that card token.
 */
+ (STPCustomer *)customerWithSingleCardTokenSource;

/**
 A Customer object with a single card source in its sources array, and
 default_source set to that card source.
 */
+ (STPCustomer *)customerWithSingleCardSourceSource;

/**
 A Customer object with two cards in its sources array, 
 one a token/card type and one a source object type.
 default_source is set to the card token.
 */
+ (STPCustomer *)customerWithCardTokenAndSourceSources;

/**
 A Customer object with a card source, and apple pay card source, and
 default_source set to the apple pay source.
 */
+ (STPCustomer *)customerWithCardAndApplePaySources;

/**
 A customer object with a sources array that includes the listed json sources
 in the order they are listed in the array.
 
 Valid keys are any STPTestJSONSource constants and the STPTestJSONCard constant.
 
 Ids for the sources will be automatically generated and will be equal to a
 string that is the index of the array of that source.
 */
+ (STPCustomer *)customerWithSourcesFromJSONKeys:(NSArray<NSString *> *)jsonSourceKeys
                                   defaultSource:(NSString *)jsonKeyForDefaultSource;

/**
 A Source object with type iDEAL
 */
+ (STPSource *)iDEALSource;

/**
 A Source object with type Alipay
 */
+ (STPSource *)alipaySource;

/**
 A Source object with type WeChat Pay
 */
+ (STPSource *)weChatPaySource;
    
/**
 A Source object with type Alipay and a native redirect url
 */
+ (STPSource *)alipaySourceWithNativeURL;

/**
 A PaymentIntent object
 */
+ (STPPaymentIntent *)paymentIntent;

/**
 A SetupIntent object
 */
+ (STPSetupIntent *)setupIntent;

/**
 A PaymentConfiguration object with a fake publishable key. Use this to avoid
 triggering our asserts when publishable key is nil or invalid. All other values
 are at their original defaults.
 */
+ (STPPaymentConfiguration *)paymentConfiguration;

/**
 A customer-scoped ephemeral key that expires in 100 seconds.
 */
+ (STPEphemeralKey *)ephemeralKey;

/**
 A customer-scoped ephemeral key that expires in 10 seconds.
 */
+ (STPEphemeralKey *)expiringEphemeralKey;

/**
 A PaymentMethod object
 */
+ (STPPaymentMethod *)paymentMethod;

/**
 A STPPaymentMethodCardParams object with a valid number, expMonth, expYear, and cvc.
 */
+ (STPPaymentMethodCardParams *)paymentMethodCardParams;

/**
 An Apple Pay Payment Method object.
 */
+ (STPPaymentMethod *)applePayPaymentMethod;

@end

@interface STPJsonSources : NSObject

@end

