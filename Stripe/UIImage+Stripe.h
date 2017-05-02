//
//  UIImage+Stripe.h
//  Stripe
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Stripe)
- (NSData *)stp_jpegDataWithMaxFileSize:(NSUInteger)maxBytes;
@end

NS_ASSUME_NONNULL_END

void linkUIImageCategory(void);
