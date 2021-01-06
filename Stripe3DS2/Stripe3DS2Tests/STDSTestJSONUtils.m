//
//  STDSTestJSONUtils.m
//  Stripe3DS2Tests
//
//  Created by Yuki Tokuhiro on 3/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSTestJSONUtils.h"

@implementation STDSTestJSONUtils

+ (NSDictionary *)jsonNamed:(NSString *)name {
    NSData *data = [self dataFromJSONFile:name];
    if (data != nil) {
        return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)kNilOptions error:nil];
    }
    return nil;
}

+ (NSBundle *)testBundle {
    return [NSBundle bundleForClass:[STDSTestJSONUtils class]];
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
