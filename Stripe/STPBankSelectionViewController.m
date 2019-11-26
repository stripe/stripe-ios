//
//  STPBankSelectionViewController.m
//  Stripe
//
//  Created by David Estes on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPBankSelectionViewController.h"

#import "NSArray+Stripe.h"
#import "STPAPIClient+Private.h"
#import "STPFPXBankStatusResponse.h"
#import "STPColorUtils.h"
#import "STPCoreTableViewController+Private.h"
#import "STPDispatchFunctions.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPSectionHeaderView.h"
#import "STPBankSelectionTableViewCell.h"
#import "STPPaymentMethodParams.h"
#import "STPPaymentMethodFPXParams.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"

static NSString *const STPBankSelectionCellReuseIdentifier = @"STPBankSelectionCellReuseIdentifier";

@interface STPBankSelectionViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPBankSelectionMethod bankMethod;
@property (nonatomic) STPFPXBankBrand selectedBank;
@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic) STPSectionHeaderView *headerView;
@property (nonatomic) BOOL loading;
@property (nonatomic) STPFPXBankStatusResponse *bankStatus;
@end

@implementation STPBankSelectionViewController

- (instancetype)initWithBankMethod:(STPBankSelectionMethod)bankMethod {
    return [self initWithBankMethod:bankMethod configuration:[STPPaymentConfiguration sharedConfiguration] theme:[STPTheme defaultTheme]];
}

- (instancetype)initWithBankMethod:(STPBankSelectionMethod)bankMethod
                   configuration:(STPPaymentConfiguration *)configuration
                           theme:(STPTheme *)theme {
    self = [super initWithTheme:theme];
    if (self) {
        NSCAssert(bankMethod == STPBankSelectionMethodFPX, @"STPBankSelectionViewController currently only supports FPX.");
        _bankMethod = bankMethod;
        _configuration = configuration;
        _selectedBank = STPFPXBankBrandUnknown;
        _apiClient = [[STPAPIClient alloc] initWithConfiguration:configuration];
        if (bankMethod == STPBankSelectionMethodFPX) {
            [self _refreshFPXStatus];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshFPXStatus) name:UIApplicationDidBecomeActiveNotification object:nil];
        }
        self.title = STPLocalizedString(@"Bank Account", @"Title for bank account selector");
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_refreshFPXStatus {
    [self.apiClient retrieveFPXBankStatusWithCompletion:^(STPFPXBankStatusResponse * _Nullable bankStatusResponse, NSError * _Nullable error) {
        if (error == nil && bankStatusResponse != nil) {
            [self _updateWithBankStatus:bankStatusResponse];
        }
    }];
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    [self.tableView registerClass:[STPBankSelectionTableViewCell class] forCellReuseIdentifier:STPBankSelectionCellReuseIdentifier];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView reloadData];
}

- (void)updateAppearance {
    [super updateAppearance];
    
    [self.tableView reloadData];
}

- (BOOL)useSystemBackButton {
    return YES;
}

- (void)_updateWithBankStatus:(STPFPXBankStatusResponse *)bankStatusResponse {
    self.bankStatus = bankStatusResponse;
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return STPFPXBankBrandUnknown;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPBankSelectionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPBankSelectionCellReuseIdentifier forIndexPath:indexPath];
    STPFPXBankBrand bankBrand = indexPath.row;
    BOOL selected = self.selectedBank == bankBrand;
    BOOL offline = self.bankStatus && ![self.bankStatus bankBrandIsOnline:bankBrand];
    [cell configureWithBank:bankBrand theme:self.theme selected:selected offline:offline enabled:!self.loading];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL topRow = (indexPath.row == 0);
    BOOL bottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);
    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!topRow];
    [cell stp_setBottomBorderHidden:!bottomRow];
    [cell stp_setFakeSeparatorColor:self.theme.quaternaryBackgroundColor];
    [cell stp_setFakeSeparatorLeftInset:15.0f];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section {
    return 27.0f;
}

- (BOOL)tableView:(__unused UITableView *)tableView shouldHighlightRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    return !self.loading;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loading) {
        return; // Don't allow user interaction if we're currently setting up a payment method
    }
    self.loading = YES;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUInteger bankIndex = indexPath.row;
    self.selectedBank = bankIndex;
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
             withRowAnimation:UITableViewRowAnimationNone];
    
    STPPaymentMethodFPXParams *fpx = [[STPPaymentMethodFPXParams alloc] init];
    fpx.bank = bankIndex;
    // Create and return a Payment Method Params object
    STPPaymentMethodParams *paymentMethodParams = [STPPaymentMethodParams paramsWithFPX:fpx
                                                                          billingDetails:nil
                                                                                metadata:nil];
    if ([self.delegate respondsToSelector:@selector(bankSelectionViewController:didCreatePaymentMethodParams:)]) {
        [self.delegate bankSelectionViewController:self didCreatePaymentMethodParams:paymentMethodParams];
    }
}

@end
