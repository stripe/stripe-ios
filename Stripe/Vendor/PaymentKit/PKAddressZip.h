//
//  PKZip.h
//  PKPayment Example
//
//  Created by Alex MacCaw on 2/1/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PKAddressZip : NSObject {
@protected
    NSString* zip;
}

@property (nonatomic, readonly) NSString* string;

+ (id)addressZipWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;
- (NSString*)string;
- (BOOL)isValid;
- (BOOL)isPartiallyValid;

@end
