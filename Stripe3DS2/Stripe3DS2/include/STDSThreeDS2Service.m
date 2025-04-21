//
//  STDSThreeDS2Service.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSThreeDS2Service.h"

#include <stdatomic.h>

#import "STDSAlreadyInitializedException.h"
#import "STDSConfigParameters.h"
#import "STDSDebuggerChecker.h"
#import "STDSDeviceInformationManager.h"
#import "STDSDirectoryServerCertificate.h"
#import "STDSException+Internal.h"
#import "STDSInvalidInputException.h"
#import "STDSLocalizedString.h"
#import "STDSJailbreakChecker.h"
#import "STDSIntegrityChecker.h"
#import "STDSNotInitializedException.h"
#import "STDSOSVersionChecker.h"
#import "STDSSecTypeUtilities.h"
#import "STDSSimulatorChecker.h"
#import "STDSThreeDSProtocolVersion.h"
#import "STDSTransaction+Private.h"
#import "STDSWarning.h"

static const int kServiceNotInitialized = 0;
static const int kServiceInitialized = 1;

static NSString * const kInternalStripeTestingConfigParam = @"kInternalStripeTestingConfigParam";
static NSString * const kIgnoreDeviceInformationRestrictionsParam = @"kIgnoreDeviceInformationRestrictionsParam";
static NSString * const kUseULTestLOAParam = @"kUseULTestLOAParam";

@implementation STDSThreeDS2Service
{
    atomic_int _initialized;

    STDSDeviceInformation *_deviceInformation;
    STDSUICustomization *_uiSettings;
    STDSConfigParameters *_configuration;
    __weak id<STDSAnalyticsDelegate> _analyticsDelegate;
}

@synthesize warnings = _warnings;

- (void)initializeWithConfig:(STDSConfigParameters *)config
                      locale:(nullable NSLocale *)locale
                  uiSettings:(nullable STDSUICustomization *)uiSettings
           analyticsDelegate:(nonnull id<STDSAnalyticsDelegate>)analyticsDelegate {
    _analyticsDelegate = analyticsDelegate;
    [self initializeWithConfig:config locale:locale uiSettings:uiSettings];
}

- (void)initializeWithConfig:(STDSConfigParameters *)config
                      locale:(nullable NSLocale *)locale
                  uiSettings:(nullable STDSUICustomization *)uiSettings {
    if (config == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:[NSString stringWithFormat:@"%@ config parameter must be non-nil.", NSStringFromSelector(_cmd)]];
    }

    int notInitialized = kServiceNotInitialized; // Can't pass a const to atomic_compare_exchange_strong_explicit so copy here
    if (!atomic_compare_exchange_strong_explicit(&_initialized, &notInitialized, kServiceInitialized, memory_order_release, memory_order_relaxed)) {
        @throw [STDSAlreadyInitializedException exceptionWithMessage:[NSString stringWithFormat:@"STDSThreeDS2Service instance %p has already been initialized.", self]];
    }

    _configuration = config;
    _uiSettings = uiSettings ? [uiSettings copy] : [STDSUICustomization defaultSettings];
    
    NSMutableArray *warnings = [NSMutableArray array];
    if ([STDSJailbreakChecker isJailbroken]) {
        STDSWarning *jailbrokenWarning = [[STDSWarning alloc] initWithIdentifier:@"SW01" message:STDSLocalizedString(@"The device is jailbroken.", @"The text for warning when a device is jailbroken") severity:STDSWarningSeverityHigh];
        [warnings addObject:jailbrokenWarning];
    }

    if (![STDSIntegrityChecker SDKIntegrityIsValid]) {
        STDSWarning *integrityWarning = [[STDSWarning alloc] initWithIdentifier:@"SW02" message:STDSLocalizedString(@"The integrity of the SDK has been tampered.", @"The text for warning when the integrity of the SDK has been tampered with") severity:STDSWarningSeverityHigh];
        [warnings addObject:integrityWarning];
    }

    if ([STDSSimulatorChecker isRunningOnSimulator]) {
        STDSWarning *simulatorWarning = [[STDSWarning alloc] initWithIdentifier:@"SW03" message:STDSLocalizedString(@"An emulator is being used to run the App.", @"The text for warning when an emulator is being used to run the application.") severity:STDSWarningSeverityHigh];
        [warnings addObject:simulatorWarning];
    }

    if ([STDSDebuggerChecker processIsCurrentlyAttachedToDebugger]) {
        STDSWarning *debuggerWarning = [[STDSWarning alloc] initWithIdentifier:@"SW04" message:STDSLocalizedString(@"A debugger is attached to the App.", @"The text for warning when a debugger is currently attached to the process.") severity:STDSWarningSeverityMedium];
        [warnings addObject:debuggerWarning];
    }
    
    if (![STDSOSVersionChecker isSupportedOSVersion]) {
        STDSWarning *versionWarning = [[STDSWarning alloc] initWithIdentifier:@"SW05" message:STDSLocalizedString(@"The OS or the OS Version is not supported.", "The text for warning when the SDK is running on an unsupported OS or OS version.") severity:STDSWarningSeverityHigh];
        [warnings addObject:versionWarning];
    }
    
    _warnings = [warnings copy];

    _deviceInformation = [STDSDeviceInformationManager deviceInformationWithWarnings:_warnings
                                                                ignoringRestrictions:[[_configuration parameterValue:kIgnoreDeviceInformationRestrictionsParam] isEqualToString:@"Y"]];

}

- (STDSTransaction *)createTransactionForDirectoryServer:(NSString *)directoryServerID
                                     withProtocolVersion:(nullable NSString *)protocolVersion {
    if (_initialized != kServiceInitialized) {
        @throw [STDSNotInitializedException exceptionWithMessage:@"STDSThreeDS2Service instance %p has not been initialized before call to %@", self, NSStringFromSelector(_cmd)];
    }

    if (directoryServerID == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"%@ directoryServerID parameter must be non-nil.", NSStringFromSelector(_cmd)];
    }

    STDSDirectoryServer directoryServer = STDSDirectoryServerForID(directoryServerID);
    if (directoryServer == STDSDirectoryServerUnknown) {
        if ([[_configuration parameterValue:kInternalStripeTestingConfigParam] isEqualToString:@"Y"]) {
            directoryServer = STDSDirectoryServerULTestRSA;
        } else {
            @throw [STDSInvalidInputException exceptionWithMessage:@"%@ is an invalid directoryServerID value", directoryServerID];
        }
    }

    if (protocolVersion != nil && ![self _supportsProtocolVersion:protocolVersion]) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"3DS2 Protocol Version %@ is not supported by this SDK", protocolVersion];
    }



    STDSTransaction *transaction = [[STDSTransaction alloc] initWithDeviceInformation:_deviceInformation
                                                                      directoryServer:directoryServer
                                                                      protocolVersion:(protocolVersion != nil) ? STDSThreeDSProtocolVersionForString(protocolVersion) : STDSThreeDSProtocolVersion2_2_0
                                                                      uiCustomization:_uiSettings
                                                                    analyticsDelegate:_analyticsDelegate];
    transaction.bypassTestModeVerification = [[_configuration parameterValue:kInternalStripeTestingConfigParam] isEqualToString:@"Y"];
    transaction.useULTestLOA = [[_configuration parameterValue:kUseULTestLOAParam] isEqualToString:@"Y"];
    return transaction;

}

- (nullable STDSTransaction *)createTransactionForDirectoryServer:(NSString *)directoryServerID
                                                      serverKeyID:(nullable NSString *)serverKeyID
                                                certificateString:(NSString *)certificateString
                                           rootCertificateStrings:(NSArray<NSString *> *)rootCertificateStrings
                                              withProtocolVersion:(nullable NSString *)protocolVersion {
    if (_initialized != kServiceInitialized) {
        @throw [STDSNotInitializedException exceptionWithMessage:@"STDSThreeDS2Service instance %p has not been initialized before call to %@", self, NSStringFromSelector(_cmd)];
    }

    if (protocolVersion != nil && ![self _supportsProtocolVersion:protocolVersion]) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"3DS2 Protocol Version %@ is not supported by this SDK", protocolVersion];
    }

    STDSTransaction *transaction = nil;

    STDSDirectoryServerCertificate *certificate = [STDSDirectoryServerCertificate customCertificateWithString:certificateString];

    if (certificate != nil) {
        transaction = [[STDSTransaction alloc] initWithDeviceInformation:_deviceInformation
                                                       directoryServerID:directoryServerID
                                                             serverKeyID:serverKeyID
                                              directoryServerCertificate:certificate
                                                  rootCertificateStrings:rootCertificateStrings
                                                         protocolVersion:(protocolVersion != nil) ? STDSThreeDSProtocolVersionForString(protocolVersion) : STDSThreeDSProtocolVersion2_2_0
                                                         uiCustomization:_uiSettings
                                                       analyticsDelegate:_analyticsDelegate];
        transaction.bypassTestModeVerification = [_configuration parameterValue:kInternalStripeTestingConfigParam] != nil;
    }

    return transaction;
}

- (nullable NSArray<STDSWarning *> *)warnings {
    if (_initialized != kServiceInitialized) {
        @throw [STDSNotInitializedException exceptionWithMessage:@"STDSThreeDS2Service instance %p has not been initialized before call to %@", self, NSStringFromSelector(_cmd)];
    }
    
    return _warnings;
}

#pragma mark - Internal

- (BOOL)_supportsProtocolVersion:(NSString *)protocolVersion {
    STDSThreeDSProtocolVersion version = STDSThreeDSProtocolVersionForString(protocolVersion);
    switch (version) {
        case STDSThreeDSProtocolVersion2_1_0:
            return YES;

        case STDSThreeDSProtocolVersion2_2_0:
            return YES;

        case STDSThreeDSProtocolVersionFallbackTest:
             // only support fallback test if we have the internal testing config param
            return [[_configuration parameterValue:kInternalStripeTestingConfigParam] isEqualToString:@"Y"];

        case STDSThreeDSProtocolVersionUnknown:
            return NO;
    }
}

@end
