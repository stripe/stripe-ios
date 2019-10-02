//
//  STPTestUtils.h
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPTestUtils : NSObject

+ (NSDictionary *)jsonNamed:(NSString *)name;

/**
 Using runtime inspection, what are all the property names for this object?

 @param object the object to introspect
 @return list of property names, usable with `valueForKey:`
 */
+ (NSArray<NSString *> *)propertyNamesOf:(NSObject *)object;

@end

