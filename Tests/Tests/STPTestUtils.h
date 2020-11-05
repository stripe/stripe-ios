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
 Custom assertion function to compare to UIImage instances.

 On iOS 9, `XCTAssertEqualObjects` incorrectly fails when provided with identical images.

 This just calls `XCTAssertEqualObjects` with the `UIImagePNGRepresentation` of each
 image. Can be removed when we drop support for iOS 9.

 @param image1 First UIImage to compare
 @param image2 Second UIImage to compare
 */
NS_INLINE void STPAssertEqualImages(UIImage *image1, UIImage *image2) {
    XCTAssertEqualObjects(UIImagePNGRepresentation(image1), UIImagePNGRepresentation(image2));
};
