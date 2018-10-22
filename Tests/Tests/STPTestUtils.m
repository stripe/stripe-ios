//
//  STPTestUtils.m
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPTestUtils.h"

@import ObjectiveC.runtime;

@implementation STPTestUtils

+ (NSDictionary *)jsonNamed:(NSString *)name {
    NSData *data = [self dataFromJSONFile:name];
    if (data != nil) {
        return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)kNilOptions error:nil];
    }
    return nil;
}

+ (NSArray<NSString *> *)propertyNamesOf:(NSObject *)object {
    uint propertyCount;
    objc_property_t *propertyList = class_copyPropertyList([object class], &propertyCount);
    NSMutableArray *propertyNames = [NSMutableArray arrayWithCapacity:propertyCount];

    for (uint i = 0; i < propertyCount; i++) {
        objc_property_t property = propertyList[i];
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        [propertyNames addObject:propertyName];
    }
    free(propertyList);
    return propertyNames;
}

#pragma mark -

+ (NSBundle *)testBundle {
    return [NSBundle bundleForClass:[STPTestUtils class]];
}

+ (NSData *)dataFromJSONFile:(NSString *)name {
    NSBundle *bundle = [self testBundle];
    NSString *path = [bundle pathForResource:name ofType:@"json"];

    if (!path) {
        // Missing JSON file
        return nil;
    }

    NSError *error = nil;
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];

    if (!jsonString) {
        // File read error
        return nil;
    }

    // Strip all lines that begin with `//`
    NSMutableArray *jsonLines = [[NSMutableArray alloc] init];

    for (NSString *line in [jsonString componentsSeparatedByString:@"\n"]) {
        if (![line hasPrefix:@"//"]) {
            [jsonLines addObject:line];
        }
    }

    return [[jsonLines componentsJoinedByString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
