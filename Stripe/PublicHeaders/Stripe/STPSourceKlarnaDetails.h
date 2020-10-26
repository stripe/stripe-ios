//
//  STPSourceKlarnaDetails.h
//  Stripe
//
//  Created by David Estes on 11/19/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Details of a Klarna source.
 */
@interface STPSourceKlarnaDetails : NSObject <STPAPIResponseDecodable>

/**
 The Klarna-specific client token. This may be used with the Klarna SDK.
 @see https://developers.klarna.com/documentation/in-app/ios/steps-klarna-payments-native/#initialization
*/
@property (nonatomic, readonly) NSString *clientToken;

/**
 The ISO-3166 2-letter country code of the customer's location.
*/
@property (nonatomic, readonly) NSString *purchaseCountry;

@end


NS_ASSUME_NONNULL_END
