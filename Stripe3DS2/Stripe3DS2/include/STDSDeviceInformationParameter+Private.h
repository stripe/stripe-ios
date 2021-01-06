//
//  STDSDeviceInformationParameter+Private.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/23/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSDeviceInformationParameter.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSDeviceInformationParameter (Private)

- (instancetype)initWithIdentifier:(NSString *)identifier
                   permissionCheck:(nullable BOOL (^)(void))permissionCheck
                        valueCheck:(id _Nullable (^)(void))valueCheck;

/// Platform: Platform that the device is using
+ (instancetype)platform;
/// Device Model: Mobile device manufacturer and model
+ (instancetype)deviceModel;
/// OS Name: Operating system name
+ (instancetype)OSName;
/// OS Version: Operating system version
+ (instancetype)OSVersion;
/// Locale: Device locale set by the user
+ (instancetype)locale;
/// Time zone: Device time zone
+ (instancetype)timeZone;
/// Advertising ID: Unique ID available for adertising and fraud detection purposes
+ (instancetype)advertisingID;
/// Screen Resolution: Pixel width and pixel height
+ (instancetype)screenResolution;
/// Device Name: User-assigned device name
+ (instancetype)deviceName;
/// IP Address: IP address of device
+ (instancetype)IPAddress;
/// Latitude: Device physical location latitude
+ (instancetype)latitude;
/// Longitude: Device physical location longitude
+ (instancetype)longitude;

/// Identifier for Vendor: Alphanumeric string that uniquely ideitifies a device to the app's vendor
+ (instancetype)identiferForVendor;
/// UserInterfaceIdiom: Style of interface to use on the current device
+ (instancetype)userInterfaceIdiom;

/// familyNames: an array of font family names available on the system
+ (instancetype)familyNames;
/// fontNamesForFamilyName: an array of font names available in a particular font family using the system font family
+ (instancetype)fontNamesForFamilyName;
/// systemFont: System font
+ (instancetype)systemFont;
/// labelFontSize: standard font size used for labels
+ (instancetype)labelFontSize;
/// buttonFontSize: standard font size used for buttons
+ (instancetype)buttonFontSize;
/// smallSystemFontSize: size of the standard small system font
+ (instancetype)smallSystemFontSize;
/// systemFontSize: size of the standard system font
+ (instancetype)systemFontSize;

/// systemLocale: the ID of the generic locale that contains fixed "backstop" settings that provide values for otherwise undefined keys
+ (instancetype)systemLocale;
/// availableLocaleIdentifiers: an array of NSString objecgts, each of which identifies a locale available on the system
+ (instancetype)availableLocaleIdentifiers;
/// preferredLanguages: the user's language preference order as an array of strings
+ (instancetype)preferredLanguages;

/// defaultTimeZone: the default time zone for the current application
+ (instancetype)defaultTimeZone;

@end

NS_ASSUME_NONNULL_END
