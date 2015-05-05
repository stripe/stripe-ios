//
//  STPStrictURLProtocol.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPNullabilityMacros.h"

static NSString * __stp_nonnull const STPStrictURLProtocolRequestKey = @"STPStrictURLProtocolRequestKey";

/**
 *  This URL protocol treats any non-20x or 30x response from checkout as an error (unlike the default UIWebView behavior, which e.g. displays a 404 page).
 */
@interface STPStrictURLProtocol : NSURLProtocol
@property (nonatomic, strong, stp_nullable) NSURLConnection *connection;
@end
