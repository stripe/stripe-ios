//
//  STDSProgressViewController.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 5/6/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STDSDirectoryServer.h"

@class STDSImageLoader, STDSUICustomization;
@protocol STDSAnalyticsDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface STDSProgressViewController : UIViewController

- (instancetype)initWithDirectoryServer:(STDSDirectoryServer)directoryServer
                        uiCustomization:(STDSUICustomization * _Nullable)uiCustomization
                      analyticsDelegate:(nullable id<STDSAnalyticsDelegate>)analyticsDelegate
                              didCancel:(void (^)(void))didCancel;

@end

NS_ASSUME_NONNULL_END
