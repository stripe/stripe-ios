//
//  STPMultipartFormDataEncoder.m
//  Stripe
//
//  Created by Charles Scalesse on 12/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPMultipartFormDataEncoder.h"
#import "STPMultipartFormDataPart.h"

@implementation STPMultipartFormDataEncoder

+ (NSData *)multipartFormDataForParts:(NSArray<STPMultipartFormDataPart *> *)parts boundary:(NSString *)boundary {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSData *boundaryData = [[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    
    for (STPMultipartFormDataPart *part in parts) {
        [data appendData:boundaryData];
        [data appendData:[part composedData]];
    }
    
    [data appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return data;
}

+ (NSString *)generateBoundary {
    return [NSString stringWithFormat:@"Stripe-iOS-%@", [[NSUUID UUID] UUIDString]];
}

@end
