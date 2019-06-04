//
//  STPSourceWeChatPayDetails.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/4/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPSourceWeChatPayDetails : NSObject <STPAPIResponseDecodable>

/**
 A URL to the WeChat App. Redirect your customer to this so they can authorize the payment.
 */
@property (nonatomic, readonly) NSString *weChatAppURL;

@end

NS_ASSUME_NONNULL_END
