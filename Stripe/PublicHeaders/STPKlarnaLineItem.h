//
//  STPKlarnaLineItem.h
//  Stripe
//
//  Created by David Estes on 11/19/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An object representing a line item in a Klarna source.
 @see https://stripe.com/docs/sources/klarna#create-source
 */

@interface STPKlarnaLineItem : NSObject

/**
 The line item's type. This is generally `sku` for a product, `tax` for taxes, and `shipping` for shipping.
 */
@property (nonatomic, copy) NSString *itemType;

/**
 The human-readable description for the line item.
 */
@property (nonatomic, copy) NSString *itemDescription;

/**
 The quantity to display for this line item.
 */
@property (nonatomic, copy) NSNumber *quantity;

/**
 The total price of this line item.
 Note: This is the total price after multiplying by the quantity, not
 the price of an individual item.
 */
@property (nonatomic, copy) NSNumber *totalAmount;

/**
Initialize this `STPKlarnaLineItem` with a set of parameters.

 @param itemType         The line item's type.
 @param itemDescription  The human-readable description for the line item.
 @param quantity         The quantity to display for this line item.
 @param totalAmount      The total price of this line item.

*/
- (instancetype)initWithItemType:(NSString *)itemType itemDescription:(NSString *)itemDescription quantity:(NSNumber *)quantity totalAmount:(NSNumber *)totalAmount;

@end

NS_ASSUME_NONNULL_END
