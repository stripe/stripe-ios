//
//  STPColorUtilsTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 5/29/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPColorUtils.h"

@interface STPColorUtilsTest : XCTestCase
@end

@implementation STPColorUtilsTest

- (void)testGrayscaleColorsIsBright {
    CGColorSpaceRef space = CGColorSpaceCreateDeviceGray();
    CGFloat components[2] = {0.0, 1.0};

    // Using 0.3 as the cutoff from bright/non-bright because that's what
    // the current implementation does.

    for (CGFloat white = 0.0; white < 0.3; white += 0.05) {
        components[0] = white;
        CGColorRef cgcolor = CGColorCreate(space, components);
        UIColor *color = [UIColor colorWithCGColor:cgcolor];

        XCTAssertFalse([STPColorUtils colorIsBright:color], @"colorWithWhite: %f", white);
        CGColorRelease(cgcolor);
    }

    for (CGFloat white = (CGFloat)0.3001; white < 2; white += 0.1) {
        components[0] = white;
        CGColorRef cgcolor = CGColorCreate(space, components);
        UIColor *color = [UIColor colorWithCGColor:cgcolor];

        XCTAssertTrue([STPColorUtils colorIsBright:color], @"colorWithWhite: %f", white);
        CGColorRelease(cgcolor);
    }
    CGColorSpaceRelease(space);
}

- (void)testBuiltinColorsIsBright {
    // This is primarily to document what colors are considered bright/dark
    NSArray<UIColor *> *brightColors = @[
                                         [UIColor brownColor],
                                         [UIColor cyanColor],
                                         [UIColor darkGrayColor],
                                         [UIColor grayColor],
                                         [UIColor greenColor],
                                         [UIColor lightGrayColor],
                                         [UIColor magentaColor],
                                         [UIColor orangeColor],
                                         [UIColor whiteColor],
                                         [UIColor yellowColor],
                                         ];
    NSArray<UIColor *> *darkColors = @[
                                       [UIColor blackColor],
                                       [UIColor blueColor],
                                       [UIColor clearColor],
                                       [UIColor purpleColor],
                                       [UIColor redColor],
                                       ];

    for (UIColor *color in brightColors) {
        XCTAssertTrue([STPColorUtils colorIsBright:color], @"%@", color);
    }

    for (UIColor *color in darkColors) {
        XCTAssertFalse([STPColorUtils colorIsBright:color], @"%@", color);
    }
}

- (void)testAllColorSpaces {
    // block to create & check brightness of color in a given color space
    void (^testColorSpace)(NSString *, BOOL) = ^(NSString *colorSpaceName, BOOL expectedToBeBright) {
        // this a bright color in almost all color spaces
        CGFloat components[] = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0};

        UIColor *color = nil;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName((__bridge CFStringRef)colorSpaceName);

        if (colorSpace) {
            CGColorRef cgcolor = CGColorCreate(colorSpace, components);

            if (cgcolor) {
                color = [UIColor colorWithCGColor:cgcolor];
            }
            CGColorRelease(cgcolor);
        }
        CGColorSpaceRelease(colorSpace);

        if (color) {
            if (expectedToBeBright) {
                XCTAssertTrue([STPColorUtils colorIsBright:color], @"%@", color);
            } else {
                XCTAssertFalse([STPColorUtils colorIsBright:color], @"%@", color);
            }
        } else {
            XCTFail(@"Could not create color for %@", colorSpaceName);
        }
    };

    NSArray *colorSpaceNames = @[
      (__bridge NSString *)kCGColorSpaceSRGB,
      (__bridge NSString *)kCGColorSpaceDCIP3,
      (__bridge NSString *)kCGColorSpaceROMMRGB,
      (__bridge NSString *)kCGColorSpaceITUR_709,
      (__bridge NSString *)kCGColorSpaceDisplayP3,
      (__bridge NSString *)kCGColorSpaceITUR_2020,
      (__bridge NSString *)kCGColorSpaceGenericRGB,
      (__bridge NSString *)kCGColorSpaceGenericXYZ,
      (__bridge NSString *)kCGColorSpaceLinearSRGB,
      (__bridge NSString *)kCGColorSpaceGenericCMYK,
      (__bridge NSString *)kCGColorSpaceGenericGray,
      (__bridge NSString *)kCGColorSpaceACESCGLinear,
      (__bridge NSString *)kCGColorSpaceAdobeRGB1998,
      (__bridge NSString *)kCGColorSpaceExtendedGray,
      (__bridge NSString *)kCGColorSpaceExtendedSRGB,
      (__bridge NSString *)kCGColorSpaceGenericRGBLinear,
      (__bridge NSString *)kCGColorSpaceExtendedLinearSRGB,
      (__bridge NSString *)kCGColorSpaceGenericGrayGamma2_2,
      ];

    if (@available(iOS 10.0, *)) {
        colorSpaceNames = [colorSpaceNames arrayByAddingObjectsFromArray:@[
                                                                           (__bridge NSString *)kCGColorSpaceLinearGray,
                                                                           (__bridge NSString *)kCGColorSpaceExtendedLinearGray,
                                                                           ]];
    }

    for (NSString *name in colorSpaceNames) {
        // CMYK is the only one where all 1's results in a dark color
        testColorSpace(name, name != (__bridge NSString *)kCGColorSpaceGenericCMYK);
    }

    if (@available(iOS 11.0, *)) {
        // in LAB all 1's is dark
        testColorSpace((__bridge NSString *)kCGColorSpaceGenericLab, NO);
    }
}

@end
