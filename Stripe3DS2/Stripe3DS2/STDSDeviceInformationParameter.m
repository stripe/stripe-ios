//
//  STDSDeviceInformationParameter.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/23/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSDeviceInformationParameter.h"

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

#import "STDSIPAddress.h"
#import "STDSSynchronousLocationManager.h"
#import "STDSVisionSupport.h"

NS_ASSUME_NONNULL_BEGIN

// Code value to use if the parameter is restricted by the region or market
static const NSString * const kParameterRestrictedCode = @"RE01";
// Code value to use if the platform version does not support the parameter or the parameter has been deprecated
static const NSString * const kParameterUnavailableCode = @"RE02";
// Code value to use if parameter collection not possible without prompting the user for permission
static const NSString * const kParameterMissingPermissionsCode = @"RE03";
// Code value to use if parameter value returned is null or blank
static const NSString * const kParameterNilCode = @"RE04";

@implementation STDSDeviceInformationParameter
{
    NSString *_identifier;
    BOOL  (^ _Nullable _permissionCheck)(void);
    id (^_valueCheck)(void);
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                   permissionCheck:(nullable BOOL (^)(void))permissionCheck
                        valueCheck:(id (^)(void))valueCheck {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _permissionCheck = [permissionCheck copy];
        _valueCheck = [valueCheck copy];
    }

    return self;
}

- (BOOL)_hasPermissions {
    if (_permissionCheck == nil) {
        return YES;
    }
    return _permissionCheck();
}

- (BOOL)_isRestricted {
    static NSSet<NSString *> *sApprovedParameters = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sApprovedParameters = [NSSet setWithObjects:
                                // platform
                                @"C001",
                                // device model
                                @"C002",
                                // OS name
                                @"C003",
                                // OS version
                                @"C004",
                                // locale
                                @"C005",
                                // time zone
                                @"C006",
                                // advertising id (i.e. hardware id)
                                @"C007",
                                // screen solution
                                @"C008",
                                nil
                                ];
    });

    return ![sApprovedParameters containsObject:_identifier];
}

- (void)collectIgnoringRestrictions:(BOOL)ignoreRestrictions withHandler:(void (^)(BOOL, NSString *, id))handler {
    if (!ignoreRestrictions && [self _isRestricted]) {
        handler(NO, _identifier, kParameterRestrictedCode);
        return;
    } else if (![self _hasPermissions]) {
        handler(NO, _identifier, kParameterMissingPermissionsCode);
        return;
    }

    NSAssert(_valueCheck != nil, @"STDSDeviceInformationParameter should not have nil _valueCheck.");
    id value = _valueCheck != nil ? _valueCheck() : nil;

    handler(value != nil, _identifier, value ?: kParameterUnavailableCode);
}

+ (NSArray<STDSDeviceInformationParameter *> *)allParameters {
    static NSArray<STDSDeviceInformationParameter *> *allParameters = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allParameters = @[

#pragma mark - Common Parameters

                          [STDSDeviceInformationParameter platform],
                          [STDSDeviceInformationParameter deviceModel],
                          [STDSDeviceInformationParameter OSName],
                          [STDSDeviceInformationParameter OSVersion],
                          [STDSDeviceInformationParameter locale],
                          [STDSDeviceInformationParameter timeZone],
                          [STDSDeviceInformationParameter dateTime],
                          [STDSDeviceInformationParameter screenResolution],
                          [STDSDeviceInformationParameter deviceName],
                          [STDSDeviceInformationParameter IPAddress],
                          [STDSDeviceInformationParameter latitude],
                          [STDSDeviceInformationParameter longitude],
                          [STDSDeviceInformationParameter applicationPackageName],
                          [STDSDeviceInformationParameter sdkAppId],
                          [STDSDeviceInformationParameter sdkVersion],


#pragma mark - iOS-Specific Parameters

                          [STDSDeviceInformationParameter identiferForVendor],
                          [STDSDeviceInformationParameter userInterfaceIdiom],
                          [STDSDeviceInformationParameter familyNames],
                          [STDSDeviceInformationParameter fontNamesForFamilyName],
                          [STDSDeviceInformationParameter systemFont],
                          [STDSDeviceInformationParameter labelFontSize],
                          [STDSDeviceInformationParameter buttonFontSize],
                          [STDSDeviceInformationParameter smallSystemFontSize],
                          [STDSDeviceInformationParameter systemFontSize],
                          [STDSDeviceInformationParameter systemLocale],
                          [STDSDeviceInformationParameter availableLocaleIdentifiers],
                          [STDSDeviceInformationParameter preferredLanguages],
                          [STDSDeviceInformationParameter defaultTimeZone],
                          [STDSDeviceInformationParameter appStoreReciptURL],
                          [STDSDeviceInformationParameter appStoreReceiptExists],
                          ];


    });

    return allParameters;
}

+ (instancetype)platform {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C001"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return @"iOS";
                                                           }];
}

+ (instancetype)deviceModel {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C002"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return [[UIDevice currentDevice] model];
                                                           }];
}

+ (instancetype)OSName {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C003"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return [[UIDevice currentDevice] systemName];
                                                           }];
}

+ (instancetype)OSVersion {
    return  [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C004"
                                                       permissionCheck:nil
                                                            valueCheck:^id _Nullable{
                                                                return [[UIDevice currentDevice] systemVersion];
                                                            }];
}

+ (instancetype)locale {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C005"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               NSLocale *locale = [NSLocale currentLocale];
                                                               NSString *language = locale.languageCode;
                                                               NSString *country = locale.countryCode;
                                                               if (language != nil && country != nil) {
                                                                   return [@[language, country] componentsJoinedByString:@"-"];
                                                               } else {
                                                                   return nil;
                                                               }
                                                           }];
}

+ (instancetype)timeZone {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C006"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                                NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
                                                                NSInteger secondsFromGMT = [localTimeZone secondsFromGMT];
                                                                
                                                                // Convert the offset to minutes
                                                                NSInteger minutesFromGMT = secondsFromGMT / 60;
                                                               
                                                                NSString *utcOffsetString = [NSString stringWithFormat:@"%ld", (long)minutesFromGMT];
                                                                
                                                                return utcOffsetString;
                                                           }];
}

+ (instancetype)screenResolution {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C008"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
#if STP_TARGET_VISION
        // Offer something reasonable
        CGRect boundsInPixels = CGRectMake(0, 0, 512, 342);
#else
        CGRect boundsInPixels = [UIScreen mainScreen].nativeBounds;
#endif
                                                               return [NSString stringWithFormat:@"%ldx%ld", (long)boundsInPixels.size.width, (long)boundsInPixels.size.height];

                                                           }];
}

+ (instancetype)deviceName
{
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C009"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return [UIDevice currentDevice].localizedModel;
                                                           }];
}

+ (instancetype)IPAddress {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C010"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return STDSCurrentDeviceIPAddress();
                                                           }];
}

+ (instancetype)latitude {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C011"
                                                      permissionCheck:^BOOL{
                                                          return [STDSSynchronousLocationManager hasPermissions];
                                                      }
                                                           valueCheck:^id _Nullable{
                                                               CLLocation *location = [[STDSSynchronousLocationManager sharedManager] deviceLocation];
                                                               return location != nil ? @(location.coordinate.latitude).stringValue : nil;
                                                           }];
}

+ (instancetype)longitude {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C012"
                                                      permissionCheck:^BOOL{
                                                          return [STDSSynchronousLocationManager hasPermissions];
                                                      }
                                                           valueCheck:^id _Nullable{
                                                               CLLocation *location = [[STDSSynchronousLocationManager sharedManager] deviceLocation];
                                                               return location != nil ? @(location.coordinate.longitude).stringValue : nil;
                                                           }];
}

+ (instancetype)applicationPackageName {
    /*
     The unique package name/bundle identifier of the application in which the
     3DS SDK is embedded.
     • iOS: obtained from the [NSBundle mainBundle] bundleIdentifier
     property.
     */
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C013"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return [[NSBundle mainBundle] bundleIdentifier];
                                                           }];
}


+ (instancetype)sdkAppId {
    /*
     Universally unique ID that is created for each installation of the 3DS
     Requestor App on a Consumer Device.
     Note: This should be the same ID that is passed to the Requestor App in
     the AuthenticationRequestParameters object (Refer to Section
     4.12.1 in the EMV 3DS SDK Specification).
     */
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C014"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                            return [STDSDeviceInformationParameter sdkAppIdentifier];
                                                           }];
}


+ (instancetype)sdkVersion {
    /*
     3DS SDK version as applied by the implementer and stored securely in the
     SDK (refer to Req 58 in the EMV 3DS SDK Specification).
     */
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C015"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return @"2.2.0";
                                                           }];
}



+ (instancetype)dateTime {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"C017"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                                NSDate *currentDate = [NSDate date];
                                                                
                                                                // Create a date formatter
                                                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                                                
                                                                // Set the time zone to UTC
                                                                [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                                                                
                                                                // Set the desired date format: YYYYMMDDHHMMSS
                                                                [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                                                                
                                                                // Convert the current date to the formatted string
                                                                NSString *utcDateString = [dateFormatter stringFromDate:currentDate];
                                                                
                                                                return utcDateString;
                                                           }];
}

+ (instancetype)identiferForVendor {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I001"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               // N.B. This can return nil if the device is locked
                                                               // We've decided to mark this case and similar as parameter unavailable,
                                                               // even though we have permission and the device _can_ provide it when
                                                               // it's in a different state
                                                               return [UIDevice currentDevice].identifierForVendor.UUIDString;
                                                           }];
}

+ (instancetype)userInterfaceIdiom {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I002"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                                switch ([UIDevice currentDevice].userInterfaceIdiom) {
                                                                    case UIUserInterfaceIdiomUnspecified:
                                                                    case UIUserInterfaceIdiomVision:
                                                                        return @"Unspecified";
                                                                    case UIUserInterfaceIdiomPhone:
                                                                        return @"iPhone";
                                                                    case UIUserInterfaceIdiomPad:
                                                                        return @"iPad";
                                                                    case UIUserInterfaceIdiomTV:
                                                                        return @"TV";
                                                                    case UIUserInterfaceIdiomCarPlay:
                                                                        return @"carPlay";
                                                                    case UIUserInterfaceIdiomMac:
                                                                        return @"Mac";
                                                                }
                                                           }];
}

+ (instancetype)familyNames {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I003"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return UIFont.familyNames;
                                                           }];
}

+ (instancetype)fontNamesForFamilyName {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I004"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               NSArray *fontNames = [UIFont fontNamesForFamilyName:[UIFont systemFontOfSize:[UIFont systemFontSize]].familyName];
                                                               if (fontNames.count == 0) {
                                                                   return @[@""]; // Workaround for TC_SDK_10176_001
                                                               }
                                                               return fontNames;
                                                           }];
}

+ (instancetype)systemFont {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I005"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return [UIFont systemFontOfSize:[UIFont systemFontSize]].fontName;
                                                           }];
}

+ (instancetype)labelFontSize {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I006"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return @([UIFont labelFontSize]).stringValue;
                                                           }];
}

+ (instancetype)buttonFontSize {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I007"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return @([UIFont buttonFontSize]).stringValue;
                                                           }];
}

+ (instancetype)smallSystemFontSize {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I008"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return @([UIFont smallSystemFontSize]).stringValue;
                                                           }];
}

+ (instancetype)systemFontSize {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I009"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return @([UIFont systemFontSize]).stringValue;
                                                           }];
}

+ (instancetype)systemLocale {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I010"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                                NSLocale *locale = [NSLocale systemLocale];
                                                                NSString *language = locale.languageCode;
                                                                NSString *country = locale.countryCode;
                                                                if (language != nil && country != nil) {
                                                                    return [@[language, country] componentsJoinedByString:@"-"];
                                                                } else {
                                                                    return nil;
                                                                }
                                                           }];
}

+ (instancetype)availableLocaleIdentifiers {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I011"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return [NSLocale availableLocaleIdentifiers];
                                                           }];
}

+ (instancetype)preferredLanguages {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I012"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                               return [NSLocale preferredLanguages];
                                                           }];
}

+ (instancetype)defaultTimeZone {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I013"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable{
                                                            NSTimeZone *defaultTimeZone = [NSTimeZone defaultTimeZone];
                                                            NSInteger secondsFromGMT = [defaultTimeZone secondsFromGMT];
                                                            
                                                            // Convert the offset to minutes
                                                            NSInteger minutesFromGMT = secondsFromGMT / 60;
                                                           
                                                            NSString *utcOffsetString = [NSString stringWithFormat:@"%ld", (long)minutesFromGMT];
                                                            
                                                            return utcOffsetString;
                                                           }];
}

+ (instancetype)appStoreReciptURL {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I014"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable {
                                                                NSString *appStoreReceiptURL = [[NSBundle mainBundle] appStoreReceiptURL].absoluteString;
                                                                if (appStoreReceiptURL) {
                                                                    return appStoreReceiptURL;
                                                                }
                                                                return kParameterNilCode;
                                                           }];
}

+ (instancetype)appStoreReceiptExists {
    return [[STDSDeviceInformationParameter alloc] initWithIdentifier:@"I015"
                                                      permissionCheck:nil
                                                           valueCheck:^id _Nullable {
                                                                // Get the receipt file URL from the app's bundle
                                                                NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                                                                
                                                                // Check if the file exists and is non-empty
                                                                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[receiptURL path]];
                                                                BOOL isFileNonEmpty = [[[NSFileManager defaultManager] attributesOfItemAtPath:[receiptURL path] error:nil] fileSize] > 0;
                                                                
                                                                // Return "true" if the receipt file exists and is non-empty, otherwise "false"
                                                                if (fileExists && isFileNonEmpty) {
                                                                    return @"true";
                                                                } else {
                                                                    return @"false";
                                                                }
                                                           }];
}

+ (NSString *)sdkAppIdentifier {
    static NSString * const appIdentifierKeyPrefix = @"STDSStripe3DS2AppIdentifierKey";
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
    NSString *appIdentifierUserDefaultsKey = [appIdentifierKeyPrefix stringByAppendingString:appVersion];
    NSString *appIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:appIdentifierUserDefaultsKey];
    if (appIdentifier == nil) {
        appIdentifier = [[NSUUID UUID] UUIDString].lowercaseString;
        // Clean up any previous app identifiers
        NSSet *previousKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] keysOfEntriesPassingTest:^BOOL (NSString *key, id obj, BOOL *stop) {
            return [key hasPrefix:appIdentifierKeyPrefix] && ![key isEqualToString:appIdentifierUserDefaultsKey];
        }];
        for (NSString *key in previousKeys) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:appIdentifier forKey:appIdentifierUserDefaultsKey];
    return appIdentifier;
}

@end

NS_ASSUME_NONNULL_END
