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

    for (CGFloat white = 0.0; white < 0.3; white += (CGFloat)0.05) {
        components[0] = white;
        CGColorRef cgcolor = CGColorCreate(space, components);
        UIColor *color = [UIColor colorWithCGColor:cgcolor];

        XCTAssertFalse([STPColorUtils colorIsBright:color], @"colorWithWhite: %f", white);
        CGColorRelease(cgcolor);
    }

    for (CGFloat white = (CGFloat)0.3001; white < 2; white += (CGFloat)0.1) {
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
    void (^testColorSpace)(const CFStringRef, BOOL) = ^(const CFStringRef colorSpaceName, BOOL expectedToBeBright) {
        // this a bright color in almost all color spaces
        CGFloat components[] = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0};

        UIColor *color = nil;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(colorSpaceName);

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

    CFStringRef colorSpaceNames[] = {
        kCGColorSpaceSRGB,
        kCGColorSpaceDCIP3,
        kCGColorSpaceROMMRGB,
        kCGColorSpaceITUR_709,
        kCGColorSpaceDisplayP3,
        kCGColorSpaceITUR_2020,
        kCGColorSpaceGenericRGB,
        kCGColorSpaceGenericXYZ,
        kCGColorSpaceLinearSRGB,
        kCGColorSpaceGenericCMYK,
        kCGColorSpaceGenericGray,
        kCGColorSpaceACESCGLinear,
        kCGColorSpaceAdobeRGB1998,
        kCGColorSpaceExtendedGray,
        kCGColorSpaceExtendedSRGB,
        kCGColorSpaceGenericRGBLinear,
        kCGColorSpaceExtendedLinearSRGB,
        kCGColorSpaceGenericGrayGamma2_2,
    };

    int colorSpaceCount = sizeof(colorSpaceNames) / sizeof(colorSpaceNames[0]);
    for (int i = 0; i < colorSpaceCount; ++i) {
        // CMYK is the only one where all 1's results in a dark color
        testColorSpace(colorSpaceNames[i], colorSpaceNames[i] != kCGColorSpaceGenericCMYK);
    }

    if (@available(iOS 10.0, *)) {
        testColorSpace(kCGColorSpaceLinearGray, YES);
        testColorSpace(kCGColorSpaceExtendedLinearGray, YES);
    }

    if (@available(iOS 11.0, *)) {
        // in LAB all 1's is dark
        testColorSpace(kCGColorSpaceGenericLab, NO);
    }
}

@end
