//
//  STPAdditionalSourceInfo.h
//  Stripe
//
//  Created by Ben Guo on 4/11/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 You can use this class to specify additional information for the SDK to use
 when creating sources.
 */
@interface STPAdditionalSourceInfo : NSObject<NSCopying>

/**
 *  Metadata associated with your user. This will be attached to any Source
 *  objects created by `STPPaymentContext`, `STPAddSourceViewController`, etc.
 *  You should consider storing any order information (e.g., order number) here.
 *  For payment methods that require additional user action, your backend will
 *  need to listen to the `source.chargeable` webhook to create a charge request.
 *  You can retrieve this metadata from the webhook event, and use it to fulfill
 *  your customer's order.
 *  https://stripe.com/docs/sources#best-practices
 */
@property(nonatomic, copy, nullable)NSDictionary<NSString *, NSString *>*metadata;

/**
 *  Some payment methods, like SOFORT, allow setting a custom statement descriptor.
 *  By default, your Stripe account’s statement descriptor is used (you can review 
 *  this in the Dashboard at https://dashboard.stripe.com/account).
 */
@property(nonatomic, copy, nullable)NSString *statementDescriptor;

@end

NS_ASSUME_NONNULL_END
