//
//  STPPaymentMethod.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPPaymentMethodEnums.h"
#import "STPPaymentOption.h"

@class STPPaymentMethodAUBECSDebit,
STPPaymentMethodBacsDebit,
STPPaymentMethodBancontact,
STPPaymentMethodBillingDetails,
STPPaymentMethodCard,
STPPaymentMethodCardPresent,
STPPaymentMethodEPS,
STPPaymentMethodFPX,
STPPaymentMethodGiropay,
STPPaymentMethodiDEAL,
STPPaymentMethodPrzelewy24,
STPPaymentMethodSEPADebit;

NS_ASSUME_NONNULL_BEGIN

/**
 PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents to collect payments.
 
 @see https://stripe.com/docs/api/payment_methods
 */
@interface STPPaymentMethod : NSObject <STPAPIResponseDecodable, STPPaymentOption>

/**
 Unique identifier for the object.
 */
@property (nonatomic, readonly) NSString *stripeId;

/**
 Time at which the object was created. Measured in seconds since the Unix epoch.
 */
@property (nonatomic, nullable, readonly) NSDate *created;

/**
 `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
 */
@property (nonatomic, readonly) BOOL liveMode;

/**
 The type of the PaymentMethod.  The corresponding, similarly named property contains additional information specific to the PaymentMethod type.
 e.g. if the type is `STPPaymentMethodTypeCard`, the `card` property is also populated.
 */
@property (nonatomic, readonly) STPPaymentMethodType type;

/**
 Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodBillingDetails *billingDetails;

/**
 If this is a card PaymentMethod (ie `self.type == STPPaymentMethodTypeCard`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodCard *card;

/**
 If this is a iDEAL PaymentMethod (ie `self.type == STPPaymentMethodTypeiDEAL`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodiDEAL *iDEAL;

/**
 If this is an FPX PaymentMethod (ie `self.type == STPPaymentMethodTypeFPX`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodFPX *fpx;

/**
 If this is a card present PaymentMethod (ie `self.type == STPPaymentMethodTypeCardPresent`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodCardPresent *cardPresent;

/**
 If this is a SEPA Debit PaymentMethod (ie `self.type == STPPaymentMethodTypeSEPADebit`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodSEPADebit *sepaDebit;

/**
 If this is a Bacs Debit PaymentMethod (ie `self.type == STPPaymentMethodTypeBacsDebit`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodBacsDebit *bacsDebit;

/**
 If this is an AU BECS Debit PaymentMethod (i.e. `self.type == STPPaymentMethodTypeAUBECSDebit`), this contains additional details.
*/
@property (nonatomic, nullable, readonly) STPPaymentMethodAUBECSDebit *auBECSDebit;

/**
 If this is a giropay PaymentMethod (i.e. `self.type == STPPaymentMethodTypeGiropay`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodGiropay *giropay;

/**
 If this is an EPS PaymentMethod (i.e. `self.type == STPPaymentMethodTypeEPS`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodEPS *eps;

/**
 If this is a Przelewy24 PaymentMethod (i.e. `self.type == STPPaymentMethodTypePrzelewy24`), this contains additional details.
*/
@property (nonatomic, nullable, readonly) STPPaymentMethodPrzelewy24 *przelewy24;

/**
 If this is a Bancontact PaymentMethod (i.e. `self.type == STPPaymentMethodTypeBancontact`), this contains additional details.
*/
@property (nonatomic, nullable, readonly) STPPaymentMethodBancontact *bancontact;

/**
 The ID of the Customer to which this PaymentMethod is saved. Nil when the PaymentMethod has not been saved to a Customer.
 */
@property (nonatomic, nullable, readonly) NSString *customerId;

/**
 Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
 
 @see https://stripe.com/docs/api#metadata
 */
@property (nonatomic, nullable, readonly) NSDictionary<NSString*, NSString *> *metadata;

@end

NS_ASSUME_NONNULL_END
