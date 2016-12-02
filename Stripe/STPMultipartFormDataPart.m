//
//  STPMultipartFormDataPart.m
//  Stripe
//
//  Created by Charles Scalesse on 12/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPMultipartFormDataPart.h"

@implementation STPMultipartFormDataPart

// MARK: - Data Composition

- (NSData *)composedData {
    NSMutableData *data = [[NSMutableData alloc] init];

    NSMutableString *contentDisposition = [NSMutableString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", _name];
    if (_filename) {
        [contentDisposition appendFormat:@"; filename=\"%@\"", _filename];
    }
    [contentDisposition appendString:@"\r\n"];
    [data appendData:[contentDisposition dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableString *contentType = [[NSMutableString alloc] init];
    if (_contentType) {
        [contentType appendFormat:@"Content-Type: %@\r\n", _contentType];
    }
    [contentType appendString:@"\r\n"];
    [data appendData:[contentType dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (_data) {
        [data appendData: _data];
    }
    [data appendData: [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    return data;
}

@end
