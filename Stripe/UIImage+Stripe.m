//
//  UIImage+Stripe.m
//  Stripe
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "UIImage+Stripe.h"

@implementation UIImage (Stripe)

- (NSData *)stp_jpegDataWithMaxFileSize:(NSUInteger)maxBytes {
    CGFloat scale = 1.0;
    NSData *imageData = UIImageJPEGRepresentation(self, 0.5);
    while (imageData.length > maxBytes) {
        scale = scale * (CGFloat) 0.8;
        CGSize newImageSize = CGSizeMake(self.size.width * scale,
                                         self.size.height *scale);
        UIGraphicsBeginImageContextWithOptions(newImageSize, NO, self.scale);
        [self drawInRect:CGRectMake(0, 0, newImageSize.width, newImageSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        imageData = UIImageJPEGRepresentation(newImage, 0.5);
    }

    return imageData;
}


@end

void linkUIImageCategory(void){}
