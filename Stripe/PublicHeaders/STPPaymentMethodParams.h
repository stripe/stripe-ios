//
//  STPPaymentMethodParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"
#import "STPPaymentMethodEnums.h"
#import "STPPaymentOption.h"

@class STPPaymentMethod,
STPPaymentMethodBacsDebitParams,
STPPaymentMethodAUBECSDebitParams,
STPPaymentMethodBancontactParams,
STPPaymentMethodBillingDetails,
STPPaymentMethodCardParams,
STPPaymentMethodEPSParams,
STPPaymentMethodFPXParams,
STPPaymentMethodGiropayParams,
STPPaymentMethodiDEALParams,
STPPaymentMethodPrzelewy24Params,
STPPaymentMethodSEPADebitParams;

NS_ASSUME_NONNULL_BEGIN

/**
 An object representing parameters used to create a PaymentMethod object.
 
 @note To create a PaymentMethod from an Apple Pay PKPaymentToken, see `STPAPIClient createPaymentMethodWithPayment:completion:`
 
 @see https://stripe.com/docs/api/payment_methods/create
 */
@interface STPPaymentMethodParams : NSObject <STPFormEncodable, STPPaymentOption>

/**
 The type of payment method.  The associated property will contain additional information (e.g. `type == STPPaymentMethodTypeCard` means `card` should also be populated).
 */
@property (nonatomic, readonly) STPPaymentMethodType type;

/**
 The raw underlying type string sent to the server.
 
 Generally you should use `type` instead unless you have a reason not to.
 You can use this if you want to create a param of a type not yet supported
 by the current version of the SDK's `STPPaymentMethodType` enum.
 
 Setting this to a value not known by the SDK causes `type` to
 return `STPPaymentMethodTypeUnknown`
 */
@property (nonatomic, copy) NSString *rawTypeString;

/**
 Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
 */
@property (nonatomic, strong, nullable) STPPaymentMethodBillingDetails *billingDetails;

/**
 If this is a card PaymentMethod, this contains the user’s card details.
 */
@property (nonatomic, strong, nullable) STPPaymentMethodCardParams *card;

/**
 If this is a iDEAL PaymentMethod, this contains details about user's bank.
 */
@property (nonatomic, nullable) STPPaymentMethodiDEALParams *iDEAL;

/**
 If this is a FPX PaymentMethod, this contains details about user's bank.
 */
@property (nonatomic, nullable) STPPaymentMethodFPXParams *fpx;

/**
 If this is a SEPA Debit PaymentMethod, this contains details about the bank to debit.
 */
@property (nonatomic, nullable) STPPaymentMethodSEPADebitParams *sepaDebit;

/**
 If this is a Bacs Debit PaymentMethod, this contains details about the bank account to debit.
 */
@property (nonatomic, nullable) STPPaymentMethodBacsDebitParams *bacsDebit;

/**
 If this is an AU BECS Debit PaymentMethod, this contains details about the bank to debit.
 */
@property (nonatomic, nullable) STPPaymentMethodAUBECSDebitParams *auBECSDebit;

/**
 If this is a giropay PaymentMethod, this contains additional details.
*/
@property (nonatomic, nullable) STPPaymentMethodGiropayParams *giropay;

/**
 If this is a Przelewy24 PaymentMethod, this contains additional details.
 */
@property (nonatomic, nullable) STPPaymentMethodPrzelewy24Params *przelewy24;

/**
 If this is an EPS PaymentMethod, this contains additional details.
*/
@property (nonatomic, nullable) STPPaymentMethodEPSParams *eps;

/**
 If this is a Bancontact PaymentMethod, this contains additional details.
 */
@property (nonatomic, nullable) STPPaymentMethodBancontactParams *bancontact;

/**
 Set of key-value pairs that you can attach to the PaymentMethod. This can be useful for storing additional information about the PaymentMethod in a structured format.
 */
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *metadata;

/**
 Creates params for a card PaymentMethod.
 
 @param card                An object containing the user's card details.
 @param billingDetails      An object containing the user's billing details.
 @param metadata            Additional information to attach to the PaymentMethod.
 */
+ (STPPaymentMethodParams *)paramsWithCard:(STPPaymentMethodCardParams *)card
                                billingDetails:(nullable STPPaymentMethodBillingDetails *)billingDetails
                                      metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for an iDEAL PaymentMethod.
 
 @param iDEAL               An object containing the user's iDEAL bank details.
 @param billingDetails      An object containing the user's billing details.
 @param metadata            Additional information to attach to the PaymentMethod.
 */
+ (STPPaymentMethodParams *)paramsWithiDEAL:(STPPaymentMethodiDEALParams *)iDEAL
                            billingDetails:(nullable STPPaymentMethodBillingDetails *)billingDetails
                                  metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for an FPX PaymentMethod.
 
 @param fpx                 An object containing the user's FPX bank details.
 @param billingDetails      An object containing the user's billing details.
 @param metadata            Additional information to attach to the PaymentMethod.
 */
+ (STPPaymentMethodParams *)paramsWithFPX:(STPPaymentMethodFPXParams *)fpx
                           billingDetails:(nullable STPPaymentMethodBillingDetails *)billingDetails
                                 metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for a SEPA Debit PaymentMethod;

 @param sepaDebit   An object containing the SEPA bank debit details.
 @param billingDetails  An object containing the user's billing details. Note that `billingDetails.name` is required for SEPA Debit PaymentMethods.
 @param metadata     Additional information to attach to the PaymentMethod.
 */
+ (nullable STPPaymentMethodParams *)paramsWithSEPADebit:(STPPaymentMethodSEPADebitParams *)sepaDebit
                                          billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                                metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for a Bacs Debit PaymentMethod;

 @param bacsDebit   An object containing the Bacs bank debit details.
 @param billingDetails  An object containing the user's billing details. Note that name, email, and address are required for Bacs Debit PaymentMethods.
 @param metadata     Additional information to attach to the PaymentMethod.
 */
+ (nullable STPPaymentMethodParams *)paramsWithBacsDebit:(STPPaymentMethodBacsDebitParams *)bacsDebit
                                          billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                                metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for an AU BECS Debit PaymentMethod;

 @param auBECSDebit   An object containing the AU BECS bank debit details.
 @param billingDetails  An object containing the user's billing details. Note that `billingDetails.name` and `billingDetails.email` are required for AU BECS Debit PaymentMethods.
 @param metadata     Additional information to attach to the PaymentMethod.
 */
+ (nullable STPPaymentMethodParams *)paramsWithAUBECSDebit:(STPPaymentMethodAUBECSDebitParams *)auBECSDebit
                                            billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                                  metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for a giropay PaymentMethod;

 @param giropay   An object containing additional giropay details.
 @param billingDetails  An object containing the user's billing details. Note that `billingDetails.name` is required for giropay PaymentMethods.
 @param metadata     Additional information to attach to the PaymentMethod.
 */
+ (nullable STPPaymentMethodParams *)paramsWithGiropay:(STPPaymentMethodGiropayParams *)giropay
                                        billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                              metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for an EPS PaymentMethod;

 @param eps   An object containing additional EPS details.
 @param billingDetails  An object containing the user's billing details. Note that `billingDetails.name` is required for EPS PaymentMethods.
 @param metadata     Additional information to attach to the PaymentMethod.
 */
+ (nonnull STPPaymentMethodParams *)paramsWithEPS:(STPPaymentMethodEPSParams *)eps
                                    billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                          metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for a Przelewy24 PaymentMethod;
 @param przelewy24   An object containing additional Przelewy24 details.
 @param billingDetails  An object containing the user's billing details. Note that `billingDetails.email` is required for Przelewy24 PaymentMethods.
 @param metadata     Additional information to attach to the PaymentMethod.
 */
+ (nullable STPPaymentMethodParams *)paramsWithPrzelewy24:(STPPaymentMethodPrzelewy24Params *)przelewy24
                                           billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                                 metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params for a Bancontact PaymentMethod;

 @param bancontact   An object containing additional Bancontact details.
 @param billingDetails  An object containing the user's billing details. Note that `billingDetails.name` is required for Bancontact PaymentMethods.
 @param metadata     Additional information to attach to the PaymentMethod.
 */
+ (nullable STPPaymentMethodParams *)paramsWithBancontact:(STPPaymentMethodBancontactParams *)bancontact
                                           billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                                 metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

/**
 Creates params from a single-use PaymentMethod. This is useful for recreating a new payment method
 with similar settings. It will return nil if used with a reusable PaymentMethod.
 
 @param paymentMethod       An object containing the original single-use PaymentMethod.
 */
+ (nullable STPPaymentMethodParams *)paramsWithSingleUsePaymentMethod:(STPPaymentMethod *)paymentMethod;

@end

NS_ASSUME_NONNULL_END
