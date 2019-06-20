//
//  STPAppInfo.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/20/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPAppInfo.h"

@implementation STPAppInfo

- (instancetype)initWithName:(NSString *)name
                   partnerId:(NSString *)partnerId
                     version:(nullable NSString *)version
                         url:(nullable NSString *)url {
    self = [super init];
    if (self) {
        _name = [name copy];
        _partnerId = [partnerId copy];
        _version = [version copy];
        _url = [url copy];
    }
    return self;
}

@end
