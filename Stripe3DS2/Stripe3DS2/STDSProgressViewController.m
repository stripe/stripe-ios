//
//  STDSProgressViewController.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 5/6/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSProgressViewController.h"

#import "STDSBundleLocator.h"
#import "STDSUICustomization.h"
#import "UIViewController+Stripe3DS2.h"
#import "STDSProcessingView.h"
#import "STDSVisionSupport.h"
#import "include/STDSAnalyticsDelegate.h"

@interface STDSProgressViewController()
@property (nonatomic, strong, nullable) STDSUICustomization *uiCustomization;
@property (nonatomic, strong) void (^didCancel)(void);
@property (nonatomic) STDSDirectoryServer directoryServer;
@property (nonatomic, weak) id<STDSAnalyticsDelegate> analyticsDelegate;
@end

@implementation STDSProgressViewController

- (instancetype)initWithDirectoryServer:(STDSDirectoryServer)directoryServer 
                        uiCustomization:(STDSUICustomization * _Nullable)uiCustomization
                      analyticsDelegate:(id<STDSAnalyticsDelegate>)analyticsDelegate
                              didCancel:(void (^)(void))didCancel {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _directoryServer = directoryServer;
        _uiCustomization = uiCustomization;
        _didCancel = didCancel;
    }
    
    return self;
}

- (void)loadView {
    NSString *imageName = STDSDirectoryServerImageName(self.directoryServer);
    UIImage *dsImage = imageName ? [UIImage imageNamed:imageName inBundle:[STDSBundleLocator stdsResourcesBundle] compatibleWithTraitCollection:nil] : nil;
    self.view = [[STDSProcessingView alloc] initWithCustomization:self.uiCustomization directoryServerLogo:dsImage];
}

#if !STP_TARGET_VISION
- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.uiCustomization.preferredStatusBarStyle;
}
#endif

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _stds_setupNavigationBarElementsWithCustomization:self.uiCustomization cancelButtonSelector:@selector(_cancelButtonTapped:)];
}

- (void)_cancelButtonTapped:(UIButton *)sender {
    self.didCancel();
}

@end
