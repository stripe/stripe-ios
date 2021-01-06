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

@interface STDSProgressViewController()
@property (nonatomic, strong, nullable) STDSUICustomization *uiCustomization;
@property (nonatomic, strong) void (^didCancel)(void);
@property (nonatomic) STDSDirectoryServer directoryServer;
@end

@implementation STDSProgressViewController

- (instancetype)initWithDirectoryServer:(STDSDirectoryServer)directoryServer uiCustomization:(STDSUICustomization * _Nullable)uiCustomization didCancel:(void (^)(void))didCancel {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.uiCustomization.preferredStatusBarStyle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _stds_setupNavigationBarElementsWithCustomization:self.uiCustomization cancelButtonSelector:@selector(_cancelButtonTapped:)];
}

- (void)_cancelButtonTapped:(UIButton *)sender {
    self.didCancel();
}

@end
