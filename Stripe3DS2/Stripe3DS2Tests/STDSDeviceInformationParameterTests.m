//
//  STDSDeviceInformationParameterTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 1/24/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSDeviceInformationParameter+Private.h"

@interface STDSDeviceInformationParameterTests : XCTestCase

@end

@implementation STDSDeviceInformationParameterTests

- (void)testNoPermissions {
    STDSDeviceInformationParameter *noPermissionParam = [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"NoPermissionID"
                                                                                                   permissionCheck:^BOOL{
                                                                                                       return NO;
                                                                                                   }
                                                                                                        valueCheck:^id _Nullable{
                                                                                                            XCTFail(@"Should not try to collect value if we don't have permission for it");
                                                                                                            return @"fail";
                                                                                                        }];
    [noPermissionParam collectIgnoringRestrictions:YES withHandler:^(BOOL collected, NSString * _Nonnull identifier, id _Nonnull value) {
        XCTAssertFalse(collected, @"Should not have collected a param we don't have permission for.");
        XCTAssertTrue([value isKindOfClass:[NSString class]], @"No permission value should be a string.");
        XCTAssertEqualObjects(value, @"RE03", @"Returned value should be 'RE03' for param with missing permissions.");
    }];
}

- (void)testNoValue {
    STDSDeviceInformationParameter *noValueParam = [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"NoValueID"
                                                                                              permissionCheck:^BOOL{
                                                                                                  return YES;
                                                                                              }
                                                                                                   valueCheck:^id _Nullable{
                                                                                                       return nil;
                                                                                                   }];
    [noValueParam collectIgnoringRestrictions:YES withHandler:^(BOOL collected, NSString * _Nonnull identifier, id _Nonnull value) {
        XCTAssertFalse(collected, @"Should not have collected a param we don't have a value for.");
        XCTAssertTrue([value isKindOfClass:[NSString class]], @"No value value should be a string.");
        XCTAssertEqualObjects(value, @"RE02", @"Returned value should be 'RE02' for param with unavailable value.");
    }];
}

- (void)testCollect {
    __block BOOL permissionCheckCalled = NO;
    __block BOOL valueCheckCalled = NO;
    __block BOOL collectedHandlerCalled = NO;

    STDSDeviceInformationParameter *param = [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"ParamID"
                                                                                       permissionCheck:^BOOL{
                                                                                           XCTAssertFalse(valueCheckCalled);
                                                                                           permissionCheckCalled = YES;
                                                                                           return YES;
                                                                                       }
                                                                                            valueCheck:^id _Nullable{
                                                                                                XCTAssertTrue(permissionCheckCalled);
                                                                                                valueCheckCalled = YES;
                                                                                                return @"param_val";
                                                                                            }];
    [param collectIgnoringRestrictions:YES withHandler:^(BOOL collected, NSString * _Nonnull identifier, id _Nonnull value) {
        XCTAssertTrue(collected, @"Should have marked value as collected.");
        XCTAssertEqualObjects(value, @"param_val", @"Inaccurate returned value.");
        XCTAssertTrue(permissionCheckCalled);
        XCTAssertTrue(valueCheckCalled);
        collectedHandlerCalled = YES;
    }];

    // This check tests that collect is synchronous for now
    XCTAssertTrue(collectedHandlerCalled);

    // reset so the permission before value check doesn't fail on the second call
    permissionCheckCalled = NO;
    valueCheckCalled = NO;

    // make sure the ignoreRestrictions param is respected
    [param collectIgnoringRestrictions:NO withHandler:^(BOOL collected, NSString * _Nonnull identifier, id _Nonnull value) {
        XCTAssertFalse(collected, @"Should not have marked value as collected.");
        XCTAssertFalse(permissionCheckCalled, @"Restrictions shouldn't even check the runtime permission.");
        XCTAssertFalse(valueCheckCalled, @"Should not have tried to get the value.");
        XCTAssertEqualObjects(value, @"RE01", @"Should return market restricted code as the value.");
    }];
}

- (void)testAllParameters {
    NSArray<STDSDeviceInformationParameter *> *allParams = [STDSDeviceInformationParameter allParameters];
    XCTAssertEqual(allParams.count, 29, @"iOS should collect 29 separate parameters.");
    NSMutableSet<NSString *> *allParamIdentifiers = [[NSMutableSet alloc] init];
    for (STDSDeviceInformationParameter *param in allParams) {
        [param collectIgnoringRestrictions:YES withHandler:^(BOOL collected, NSString * _Nonnull identifier, id _Nonnull value) {
            [allParamIdentifiers addObject:identifier];
        }];
    }
    XCTAssertEqual(allParamIdentifiers.count, allParams.count, @"Sanity check that there are not duplicate identifiers.");
    NSArray<NSString *> *expectedIdentifiers = @[
                                                 @"C001",
                                                 @"C002",
                                                 @"C003",
                                                 @"C004",
                                                 @"C005",
                                                 @"C006",
                                                 @"C007",
                                                 @"C008",
                                                 @"C009",
                                                 @"C010",
                                                 @"C011",
                                                 @"C012",
                                                 @"C013",
                                                 @"C014",
                                                 @"C015",
                                                 @"I001",
                                                 @"I002",
                                                 @"I003",
                                                 @"I004",
                                                 @"I005",
                                                 @"I006",
                                                 @"I007",
                                                 @"I008",
                                                 @"I009",
                                                 @"I010",
                                                 @"I011",
                                                 @"I012",
                                                 @"I013",
                                                 @"I014",
                                                 ];
    for (NSString *identifier in expectedIdentifiers) {
        XCTAssertTrue([allParamIdentifiers containsObject:identifier], @"Missing identifier %@", identifier);
    }
}

- (void)testOnlyApprovedIdentifiers {
    NSArray<STDSDeviceInformationParameter *> *allParams = [STDSDeviceInformationParameter allParameters];
    NSMutableSet<NSString *> *collectedParameterIdentifiers = [[NSMutableSet alloc] init];
    for (STDSDeviceInformationParameter *param in allParams) {
        [param collectIgnoringRestrictions:NO withHandler:^(BOOL collected, NSString * _Nonnull identifier, id _Nonnull value) {

            if (collected) {
                [collectedParameterIdentifiers addObject:identifier];
            }
        }];
    }
    NSArray<NSString *> *expectedIdentifiers = @[
                                                 @"C001",
                                                 @"C002",
                                                 @"C003",
                                                 @"C004",
                                                 @"C005",
                                                 @"C006",
                                                 @"C007",
                                                 @"C008",
                                                 ];
    XCTAssertEqual(collectedParameterIdentifiers.count, expectedIdentifiers.count, @"Should only have collected the expected amount.");

    for (NSString *identifier in expectedIdentifiers) {
        XCTAssertTrue([collectedParameterIdentifiers containsObject:identifier], @"Missing identifier %@", identifier);
    }
}

- (void)testIdentifiersAccurate {
    NSDictionary<NSString *, STDSDeviceInformationParameter *> *expectedIdentifiers = @{
                                                                                        @"C001": [STDSDeviceInformationParameter platform],
                                                                                        @"C002": [STDSDeviceInformationParameter deviceModel],
                                                                                        @"C003": [STDSDeviceInformationParameter OSName],
                                                                                        @"C004": [STDSDeviceInformationParameter OSVersion],
                                                                                        @"C005": [STDSDeviceInformationParameter locale],
                                                                                        @"C006": [STDSDeviceInformationParameter timeZone],
                                                                                        @"C007": [STDSDeviceInformationParameter advertisingID],
                                                                                        @"C008": [STDSDeviceInformationParameter screenResolution],
                                                                                        @"C009": [STDSDeviceInformationParameter deviceName],
                                                                                        @"C010": [STDSDeviceInformationParameter IPAddress],
                                                                                        @"C011": [STDSDeviceInformationParameter latitude],
                                                                                        @"C012": [STDSDeviceInformationParameter longitude],
                                                                                        @"I001": [STDSDeviceInformationParameter identiferForVendor],
                                                                                        @"I002": [STDSDeviceInformationParameter userInterfaceIdiom],
                                                                                        @"I003": [STDSDeviceInformationParameter familyNames],
                                                                                        @"I004": [STDSDeviceInformationParameter fontNamesForFamilyName],
                                                                                        @"I005": [STDSDeviceInformationParameter systemFont],
                                                                                        @"I006": [STDSDeviceInformationParameter labelFontSize],
                                                                                        @"I007": [STDSDeviceInformationParameter buttonFontSize],
                                                                                        @"I008": [STDSDeviceInformationParameter smallSystemFontSize],
                                                                                        @"I009": [STDSDeviceInformationParameter systemFontSize],
                                                                                        @"I010": [STDSDeviceInformationParameter systemLocale],
                                                                                        @"I011": [STDSDeviceInformationParameter availableLocaleIdentifiers],
                                                                                        @"I012": [STDSDeviceInformationParameter preferredLanguages],
                                                                                        @"I013": [STDSDeviceInformationParameter defaultTimeZone],
                                                                                        };

    [expectedIdentifiers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, STDSDeviceInformationParameter * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj collectIgnoringRestrictions:YES withHandler:^(BOOL collected, NSString * _Nonnull identifier, id _Nonnull value) {
            XCTAssertEqualObjects(key, identifier);
        }];
    }];
}

#pragma mark - App ID

- (void)testSDKAppIdentifier {
    // xctest in Xcode 13 uses the Xcode version for the current app id string, previous versions are empty
    NSString *appIdentifierKeyPrefix = @"STDSStripe3DS2AppIdentifierKey";
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
    NSString *appIdentifierUserDefaultsKey = [appIdentifierKeyPrefix stringByAppendingString:appVersion];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:appIdentifierUserDefaultsKey];
    NSString *appId = [STDSDeviceInformationParameter sdkAppIdentifier];
    XCTAssertNotNil(appId);
    XCTAssertEqualObjects(appId, [[NSUserDefaults standardUserDefaults] stringForKey:appIdentifierUserDefaultsKey]);
}

@end
