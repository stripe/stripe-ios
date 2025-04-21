//
//  STDSTransaction+Private.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSTransaction.h"

@class STDSDeviceInformation;
@class STDSDirectoryServerCertificate;
@protocol STDSAnalyticsDelegate;

#import "STDSDirectoryServer.h"
#import "STDSThreeDSProtocolVersion+Private.h"
#import "STDSUICustomization.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSTransaction ()

- (instancetype)initWithDeviceInformation:(STDSDeviceInformation *)deviceInformation
                          directoryServer:(STDSDirectoryServer)directoryServer
                          protocolVersion:(STDSThreeDSProtocolVersion)protocolVersion
                          uiCustomization:(STDSUICustomization *)uiCustomization
                        analyticsDelegate:(nullable id<STDSAnalyticsDelegate>)analyticsDelegate;

- (instancetype)initWithDeviceInformation:(STDSDeviceInformation *)deviceInformation
                        directoryServerID:(NSString *)directoryServerID
                              serverKeyID:(nullable NSString *)serverKeyID
               directoryServerCertificate:(STDSDirectoryServerCertificate *)directoryServerCertificate
                   rootCertificateStrings:(NSArray<NSString *> *)rootCertificateStrings
                          protocolVersion:(STDSThreeDSProtocolVersion)protocolVersion
                          uiCustomization:(STDSUICustomization *)uiCustomization
                        analyticsDelegate:(nullable id<STDSAnalyticsDelegate>)analyticsDelegate;

@property (nonatomic, strong) NSTimer *timeoutTimer;
@property (nonatomic) BOOL bypassTestModeVerification; // Should be used during internal testing ONLY
@property (nonatomic) BOOL useULTestLOA; // Should only be used when running tests with the UL reference app

@end

NS_ASSUME_NONNULL_END
