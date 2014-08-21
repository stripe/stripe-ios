//
//  PKZip.h
//  PKPayment Example
//
//  Created by Alex MacCaw on 2/1/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PKComponent.h"

@interface PKAddressZip : PKComponent {
@protected
    NSString *_zip;
}

@property (nonatomic, readonly) NSString *string;

+ (instancetype)addressZipWithString:(NSString *)string;
- (instancetype)initWithString:(NSString *)string;

@end
