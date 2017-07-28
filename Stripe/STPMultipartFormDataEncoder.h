//
//  STPMultipartFormDataEncoder.h
//  Stripe
//
//  Created by Charles Scalesse on 12/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STPMultipartFormDataPart;

/**
 Encoder class to generate the HTTP body data for a multipart/form-data request.
 @see https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4
 */
@interface STPMultipartFormDataEncoder : NSObject

/**
 Generates the HTTP body data from an array of parts.
 */
+ (NSData *)multipartFormDataForParts:(NSArray<STPMultipartFormDataPart *> *)parts boundary:(NSString *)boundary;

/**
 Generates a unique boundary string to be used between parts.
 */
+ (NSString *)generateBoundary;

@end

NS_ASSUME_NONNULL_END
