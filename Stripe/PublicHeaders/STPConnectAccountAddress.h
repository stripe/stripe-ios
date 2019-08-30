//
//  STPConnectAccountAddress.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An address to use with `STPConnectAccountParams`.
 */
@interface STPConnectAccountAddress : NSObject <STPFormEncodable>

/**
 City, district, suburb, town, or village.
 
 For addresses in Japan: City or ward.
 */
@property (nonatomic, copy, nullable) NSString *city;

/**
 Two-letter country code (ISO 3166-1 alpha-2).
 
 @see https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
 */
@property (nonatomic, copy, nullable) NSString *country;

/**
 Address line 1 (e.g., street, PO Box, or company name).
 
 For addresses in Japan: Block or building number.
 */
@property (nonatomic, copy, nullable) NSString *line1;

/**
 Address line 2 (e.g., apartment, suite, unit, or building).
 
 For addresses in Japan: Building details.
 */
@property (nonatomic, copy, nullable) NSString *line2;

/**
 ZIP or postal code.
 */
@property (nonatomic, copy, nullable) NSString *postalCode;

/**
 State, county, province, or region.
 
 For addresses in Japan: Prefecture.
 */
@property (nonatomic, copy, nullable) NSString *state;

/**
 Town or cho-me.
 
 This property only applies to Japanese addresses.
 */
@property (nonatomic, copy, nullable) NSString *town;

@end

NS_ASSUME_NONNULL_END
