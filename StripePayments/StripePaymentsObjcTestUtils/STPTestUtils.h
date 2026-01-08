//
//  STPTestUtils.h
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface STPTestUtils : NSObject

+ (NSDictionary *)jsonNamed:(NSString *)name;

/**
 Using runtime inspection, what are all the property names for this object?

 @param object the object to introspect
 @return list of property names, usable with `valueForKey:`
 */
+ (NSArray<NSString *> *)propertyNamesOf:(NSObject *)object;

@end

/**
 Calls FBSnapshotVerifyView with a default 2% per-pixel color differentiation, as M1 and Intel machines render shadows differently.
 @param view The view to snapshot.
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define STPSnapshotVerifyView(view__, identifier__) \
FBSnapshotVerifyViewWithPixelOptions(view__, identifier__, FBSnapshotTestCaseDefaultSuffixes(), 0.02, 0)

