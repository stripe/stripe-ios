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

    // Try something smarter first
    if (imageData.length > maxBytes) {
        // Assuming jpeg file size roughly scales linearly with area of the image
        // which is ~correct (although breaks down at really small file sizes)
        CGFloat percentSmallerNeeded = (CGFloat) maxBytes / imageData.length;

        // Shrink to a little bit less than we need to try to ensure we're under
        // (otherwise its likely our first pass will be over the limit due to
        // compression variance and floating point rounding)
        scale = scale * (CGFloat) (percentSmallerNeeded - (percentSmallerNeeded * 0.05));

        do {
            CGSize newImageSize = CGSizeMake((CGFloat)floor(self.size.width * scale),
                                             (CGFloat)floor(self.size.height *scale));
            UIGraphicsBeginImageContextWithOptions(newImageSize, NO, self.scale);
            [self drawInRect:CGRectMake(0, 0, newImageSize.width, newImageSize.height)];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            imageData = UIImageJPEGRepresentation(newImage, 0.5);

            // If the smart thing doesn't work, just start scaling down a bit on a loop until we get there
            scale = scale * (CGFloat) 0.7;
        } while (imageData.length > maxBytes);

    }
    return imageData;
}


@end

void linkUIImageCategory(void){}
