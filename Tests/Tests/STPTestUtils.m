//
//  STPTestUtils.m
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPTestUtils.h"

@implementation STPTestUtils

+ (NSBundle *)testBundle {
    return [NSBundle bundleForClass:[STPTestUtils class]];
}

+ (NSDictionary *)jsonNamed:(NSString *)name {
    NSData *data = [self dataFromJSONFile:name];
    if (data != nil) {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    return nil;
}

+ (NSData *)dataFromJSONFile:(NSString *)name {
    NSBundle *bundle = [self testBundle];
    NSString *path = [bundle pathForResource:name ofType:@"json"];
    if (path != nil) {
        return [NSData dataWithContentsOfFile:path];
    }
    return nil;
}

@end
