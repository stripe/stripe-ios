//
//  STPSourceRedirect.h
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

/**
 *  Redirect status types for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceRedirectStatus) {
    STPSourceRedirectStatusPending,
    STPSourceRedirectStatusSucceeded,
    STPSourceRedirectStatusFailed,
    STPSourceRedirectStatusUnknown
};

/**
 *  Information related to a source's redirect flow.
 */
@interface STPSourceRedirect : NSObject<STPAPIResponseDecodable>

/**
 *  You cannot directly instantiate an `STPSourceRedirect`. You should only use one that is part of an existing `STPSource` object.
 */
- (nonnull instancetype) init __attribute__((unavailable("You cannot directly instantiate an STPSourceRedirect. You should only use one that is part of an existing STPSource object.")));

/**
 *  The URL you provide to redirect the customer to after they authenticated their payment.
 */
@property (nonatomic, readonly, nullable) NSURL *returnURL;

/**
 *  The status of the redirect.
 */
@property (nonatomic, readonly) STPSourceRedirectStatus status;

/**
 *  The URL provided to you to redirect a customer to as part of a redirect authentication flow.
 */
@property (nonatomic, readonly, nullable) NSURL *url;

@end
