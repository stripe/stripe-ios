//
//  STPSourceInfoViewController.m
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceInfoViewController.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPBancontactSourceInfoDataSource.h"
#import "STPCoreTableViewController+Private.h"
#import "STPGiropaySourceInfoDataSource.h"
#import "STPIDEALSourceInfoDataSource.h"
#import "STPInfoFooterView.h"
#import "STPLocalizationUtils.h"
#import "STPOptionTableViewCell.h"
#import "STPPaymentMethodType.h"
#import "STPSectionHeaderView.h"
#import "STPSelectorDataSource.h"
#import "STPSofortSourceInfoDataSource.h"
#import "STPSourceParams.h"
#import "STPSource+Private.h"
#import "STPTextFieldTableViewCell.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"

typedef NS_ENUM(NSUInteger, STPSourceInfoSection) {
    STPSourceInfoFirstSection = 0,
    STPSourceInfoSelectorSection = 1,
};

@interface STPSourceInfoViewController () <UITableViewDelegate, UITableViewDataSource, STPTextFieldTableViewCellDelegate>

@property(nonatomic)UIBarButtonItem *doneItem;
@property(nonatomic)STPSourceInfoDataSource *dataSource;
@property(nonatomic)STPSectionHeaderView *firstSectionHeaderView;
@property(nonatomic)STPSectionHeaderView *selectorHeaderView;
@property(nonatomic)STPInfoFooterView *footerView;
@property(nonatomic, copy)STPSourceInfoCompletionBlock completion;

@end

@implementation STPSourceInfoViewController

+ (BOOL)canCollectInfoForSourceType:(STPSourceType)type {
    switch (type) {
        case STPSourceTypeBancontact:
        case STPSourceTypeGiropay:
        case STPSourceTypeIDEAL:
        case STPSourceTypeSofort:
            return YES;
        default:
            return NO;
    }
}

- (nullable instancetype)initWithSourceType:(STPSourceType)type
                                     amount:(NSInteger)amount
                              configuration:(__unused STPPaymentConfiguration *)configuration
                       prefilledInformation:(STPUserInformation *)prefilledInformation
                                      theme:(STPTheme *)theme
                                 completion:(STPSourceInfoCompletionBlock)completion {
    self = [super initWithTheme:theme];
    if (![[self class] canCollectInfoForSourceType:type]) {
        return nil;
    }
    if (self) {
        _completion = completion;
        STPSourceInfoDataSource *dataSource;
        STPSourceParams *sourceParams = [STPSourceParams new];
        sourceParams.type = type;
        sourceParams.currency = @"eur";
        sourceParams.amount = @(amount);
        // TODO: get returnURL from STPPaymentConfiguration
        switch (type) {
            case STPSourceTypeBancontact: {
                dataSource = [[STPBancontactSourceInfoDataSource alloc] initWithSourceParams:sourceParams
                                                                        prefilledInformation:prefilledInformation];
                break;
            }
            case STPSourceTypeGiropay:
                dataSource = [[STPGiropaySourceInfoDataSource alloc] initWithSourceParams:sourceParams
                                                                     prefilledInformation:prefilledInformation];
                break;
            case STPSourceTypeIDEAL:
                dataSource = [[STPIDEALSourceInfoDataSource alloc] initWithSourceParams:sourceParams
                                                                   prefilledInformation:prefilledInformation];
                break;
            case STPSourceTypeSofort:
                dataSource = [[STPSofortSourceInfoDataSource alloc] initWithSourceParams:sourceParams
                                                                    prefilledInformation:prefilledInformation];
                break;
            default:
                dataSource = [[STPSourceInfoDataSource alloc] init];
                break;
        }
        _dataSource = dataSource;
        NSString *template = STPLocalizedString(@"Pay with %@", @"Pay with {payment method}");
        NSString *paymentMethodLabel = self.dataSource.paymentMethodType.paymentMethodLabel;
        self.title = [NSString stringWithFormat:template, paymentMethodLabel];
    }
    return self;
}

- (STPSourceParams *)completeSourceParams {
    if (self.dataSource.requiresUserVerification) {
        return nil;
    } else {
        return self.dataSource.completeSourceParams;
    }
}

- (void)createAndSetupViews {
    [super createAndSetupViews];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:STPLocalizedString(@"Continue", @"Text for continue button")
                                                                 style:UIBarButtonItemStyleDone
                                                                target:self
                                                                action:@selector(nextPressed:)];
    self.doneItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = NO;

    STPSectionHeaderView *firstSectionHeader = [STPSectionHeaderView new];
    firstSectionHeader.title = STPLocalizedString(@"Bank Account Information", @"Title for bank account information form");
    firstSectionHeader.buttonHidden = YES;
    self.firstSectionHeaderView = firstSectionHeader;

    STPSectionHeaderView *selectorHeader = [STPSectionHeaderView new];
    if (self.dataSource.selectorDataSource) {
        selectorHeader.title = [self.dataSource.selectorDataSource selectorTitle];
    }
    selectorHeader.buttonHidden = YES;
    self.selectorHeaderView = selectorHeader;

    STPInfoFooterView *footerView = [STPInfoFooterView new];
    NSString *template = STPLocalizedString(@"You'll be redirected to %@ to finish your payment.", @"You'll be redirected to {bank name} to finish your payment.");
    NSString *paymentMethodLabel = self.dataSource.paymentMethodType.paymentMethodLabel;
    footerView.textView.text = [NSString stringWithFormat:template, paymentMethodLabel];
    self.footerView = footerView;

    self.tableView.allowsSelection = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[STPOptionTableViewCell class] forCellReuseIdentifier:STPOptionCellReuseIdentifier];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    CGFloat headerHeight = 20;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, headerHeight, headerHeight)];
    self.tableView.tableHeaderView = headerView;

    STPTextFieldTableViewCell *lastCell = [self.dataSource.cells lastObject];
    for (STPTextFieldTableViewCell *cell in self.dataSource.cells) {
        cell.delegate = self;
        cell.lastInList = (cell == lastCell);
    }

    [self updateDoneButton];
}

- (void)endEditing {
    [self.view endEditing:NO];
}

- (void)updateAppearance {
    [super updateAppearance];

    self.view.backgroundColor = self.theme.primaryBackgroundColor;

    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    [self.doneItem stp_setTheme:navBarTheme];
    self.firstSectionHeaderView.theme = self.theme;
    self.selectorHeaderView.theme = self.theme;
    self.footerView.theme = self.theme;

    for (STPTextFieldTableViewCell *cell in self.dataSource.cells) {
        cell.theme = self.theme;
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self stp_beginObservingKeyboardAndInsettingScrollView:self.tableView
                                             onChangeBlock:nil];
    [[self firstEmptyField] becomeFirstResponder];
}

- (UIResponder *)firstEmptyField {
    for (STPTextFieldTableViewCell *cell in self.dataSource.cells) {
        if (cell.contents.length == 0) {
            return cell;
        }
    }
    return nil;
}

- (void)handleBackOrCancelTapped:(__unused id)sender {
    if (self.completion) {
        self.completion(nil);
    }
}

- (void)nextPressed:(__unused id)sender {
    if (self.completion) {
        STPSourceParams *params = [self.dataSource completeSourceParams];
        self.completion(params);
    }
}

- (void)updateDoneButton {
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = self.validContents;
}

- (BOOL)validContents {
    return self.dataSource.completeSourceParams != nil;
}

- (STPTextFieldTableViewCell *)cellBeforeCell:(STPTextFieldTableViewCell *)cell {
    NSInteger index = [self.dataSource.cells indexOfObject:cell];
    return [self.dataSource.cells stp_boundSafeObjectAtIndex:index - 1];
}

- (STPTextFieldTableViewCell *)cellAfterCell:(STPTextFieldTableViewCell *)cell {
    NSInteger index = [self.dataSource.cells indexOfObject:cell];
    return [self.dataSource.cells stp_boundSafeObjectAtIndex:index + 1];
}

#pragma mark - STPTextFieldTableViewCellDelegate

- (void)textFieldTableViewCellDidUpdateText:(__unused STPTextFieldTableViewCell *)cell {
    [self updateDoneButton];
}

- (void)textFieldTableViewCellDidReturn:(STPTextFieldTableViewCell *)cell {
    STPTextFieldTableViewCell *nextCell = [self cellAfterCell:cell];
    if (nextCell) {
        [nextCell becomeFirstResponder];
    } else {
        [self endEditing];
    }
}

- (void)textFieldTableViewCellDidBackspaceOnEmpty:(STPTextFieldTableViewCell *)cell {
    [[self cellBeforeCell:cell] becomeFirstResponder];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    if (self.dataSource.selectorDataSource) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    if (section == STPSourceInfoFirstSection) {
        return [self.dataSource.cells count];
    } else {
        if (self.dataSource.selectorDataSource) {
            return [self.dataSource.selectorDataSource numberOfRowsInSelector];
        } else {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == STPSourceInfoFirstSection) {
        cell = [self.dataSource.cells stp_boundSafeObjectAtIndex:indexPath.row];
    } else if (indexPath.section == STPSourceInfoSelectorSection && self.dataSource.selectorDataSource) {
        id<STPSelectorDataSource> selectorDataSource = self.dataSource.selectorDataSource;
        STPOptionTableViewCell *optionCell = [tableView dequeueReusableCellWithIdentifier:STPOptionCellReuseIdentifier forIndexPath:indexPath];
        optionCell.theme = self.theme;
        optionCell.titleLabel.text = [selectorDataSource selectorTitleForRow:indexPath.row];
        optionCell.leftIcon.image = [selectorDataSource selectorImageForRow:indexPath.row];
        optionCell.selected = (indexPath.row == selectorDataSource.selectedRow);
        cell = optionCell;
    } else {
        cell = [UITableViewCell new];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == STPSourceInfoSelectorSection && self.dataSource.selectorDataSource) {
        id<STPSelectorDataSource> selectorDataSource = self.dataSource.selectorDataSource;
        NSString *value = [selectorDataSource selectorValueForRow:indexPath.row];
        [selectorDataSource selectRowWithValue:value];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:STPSourceInfoSelectorSection]
                 withRowAnimation:UITableViewRowAnimationFade];
        [self updateDoneButton];
    }
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

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGSize fittingSize = CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX);
    if (section == STPSourceInfoFirstSection && self.dataSource.cells.count > 0) {
        return [self.firstSectionHeaderView sizeThatFits:fittingSize].height;
    } else if (section == STPSourceInfoSelectorSection && self.dataSource.selectorDataSource) {
        return [self.selectorHeaderView sizeThatFits:fittingSize].height;
    }
    return 0.01f;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return [UIView new];
    } else if (section == STPSourceInfoFirstSection) {
        return self.firstSectionHeaderView;
    } else if (section == STPSourceInfoSelectorSection) {
        return self.selectorHeaderView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSInteger numberOfSections = [tableView numberOfSections];
    if (numberOfSections == 1 || section == STPSourceInfoSelectorSection) {
        return [self.footerView heightForWidth:CGRectGetWidth(self.tableView.frame)];
    } else if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    } else {
        return 27.0f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSInteger numberOfSections = [tableView numberOfSections];
    if (numberOfSections == 1 || section == STPSourceInfoSelectorSection) {
        return self.footerView;
    } else {
        return [UIView new];
    }
}

- (void)scrollViewDidScroll:(__unused UIScrollView *)scrollView {
    [self endEditing];
}

@end
