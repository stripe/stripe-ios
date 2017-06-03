//
//  STPPaymentMethodsInternalViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodsInternalViewController.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPAddCardViewController+Private.h"
#import "STPAddSourceViewController+Private.h"
#import "STPColorUtils.h"
#import "STPCoreTableViewController+Private.h"
#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethodType+Private.h"
#import "STPPaymentMethodTableViewCell.h"
#import "STPSectionHeaderView.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UITableViewCell+Stripe_Borders.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";
static NSInteger STPPaymentMethodSavedPaymentsSection = 0;
static NSInteger STPPaymentMethodNewPaymentsSection = 1;

@interface STPPaymentMethodsInternalViewController()<UITableViewDataSource, UITableViewDelegate, STPAddCardViewControllerDelegate, STPAddSourceViewControllerDelegate>

@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic) STPUserInformation *prefilledInformation;
@property (nonatomic) STPAdditionalSourceInfo *sourceInformation;
@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic) NSArray<id<STPPaymentMethod>> *savedPaymentMethods;
@property (nonatomic) NSArray<STPPaymentMethodType *> *availablePaymentTypes;
@property (nonatomic) id<STPPaymentMethod> selectedPaymentMethod;
@property (nonatomic, weak) id<STPPaymentMethodsInternalViewControllerDelegate> delegate;
@property (nonatomic) STPSectionHeaderView *moreSectionHeaderView;

@end

@implementation STPPaymentMethodsInternalViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme
                 prefilledInformation:(STPUserInformation *)prefilledInformation
                    sourceInformation:(STPAdditionalSourceInfo *)sourceInformation
                      shippingAddress:(STPAddress *)shippingAddress
                   paymentMethodTuple:(STPPaymentMethodTuple *)tuple
                             delegate:(id<STPPaymentMethodsInternalViewControllerDelegate>)delegate {
    self = [super initWithTheme:theme];
    if (self) {
        _configuration = configuration;
        _prefilledInformation = prefilledInformation;
        _sourceInformation = sourceInformation;
        _shippingAddress = shippingAddress;
        _savedPaymentMethods = tuple.savedPaymentMethods;
        _availablePaymentTypes = tuple.availablePaymentTypes;
        _selectedPaymentMethod = tuple.selectedPaymentMethod;
        _delegate = delegate;
    }
    self.title = STPLocalizedString(@"Payment Method", @"Title for Payment Method screen");
    return self;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[STPPaymentMethodTableViewCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 35)];

    STPSectionHeaderView *headerView = [STPSectionHeaderView new];
    headerView.buttonHidden = YES;
    headerView.title = STPLocalizedString(@"MORE OPTIONS", @"Title for payment options section");
    self.moreSectionHeaderView = headerView;
    [self.moreSectionHeaderView setNeedsLayout];
}

- (void)updateAppearance {
    [super updateAppearance];

    self.view.backgroundColor = self.theme.primaryBackgroundColor;
    self.moreSectionHeaderView.theme = self.theme;
}

- (void)handleBackOrCancelTapped:(__unused id)sender {
    [self.delegate internalViewControllerDidCancel];
}

- (void)handleBackOrCancelTapped:(__unused id)sender {
    [self.delegate internalViewControllerDidCancel];
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentMethodSavedPaymentsSection) {
        return self.savedPaymentMethods.count;
    } else if (section == STPPaymentMethodNewPaymentsSection) {
        return self.availablePaymentTypes.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPPaymentMethodTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
    id<STPPaymentMethod> paymentMethod;
    if (indexPath.section == STPPaymentMethodSavedPaymentsSection) {
        paymentMethod = [self.savedPaymentMethods stp_boundSafeObjectAtIndex:indexPath.row];

    } else {
        paymentMethod = [self.availablePaymentTypes stp_boundSafeObjectAtIndex:indexPath.row];
    }
    [cell configureWithPaymentMethod:paymentMethod theme:self.theme];
    cell.selected = [paymentMethod isEqual:self.selectedPaymentMethod];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<STPPaymentMethod> paymentMethod;
    if (indexPath.section == STPPaymentMethodSavedPaymentsSection) {
        paymentMethod = [self.savedPaymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
    } else {
        paymentMethod = [self.availablePaymentTypes stp_boundSafeObjectAtIndex:indexPath.row];
    }

    if ([paymentMethod isKindOfClass:[STPPaymentMethodType class]]
        && [(STPPaymentMethodType *)paymentMethod convertsToSourceAtSelection]) {
        // Go to create screen
        STPPaymentMethodType *paymentType = (STPPaymentMethodType *)paymentMethod;

        STPPaymentConfiguration *config = [self.configuration copy];

        if ([paymentType isEqual:[STPPaymentMethodType card]]
            && !config.useSourcesForCards) {
            // Go to Add Card VC
            STPAddCardViewController *paymentCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:config theme:self.theme];
            paymentCardViewController.delegate = self;
            paymentCardViewController.prefilledInformation = self.prefilledInformation;
            paymentCardViewController.shippingAddress = self.shippingAddress;
            [self.navigationController pushViewController:paymentCardViewController animated:YES];
        }
        else {
            STPAddSourceViewController *addSourceViewController = [[STPAddSourceViewController alloc] initWithSourceType:paymentType.sourceType
                                                                                                           configuration:self.configuration
                                                                                                                   theme:self.theme];
            if (addSourceViewController) {
                addSourceViewController.delegate = self;
                addSourceViewController.prefilledInformation = self.prefilledInformation;
                addSourceViewController.sourceInformation = self.sourceInformation;
                addSourceViewController.shippingAddress = self.shippingAddress;
                [self.navigationController pushViewController:addSourceViewController
                                                     animated:YES];
            }
        }
    }
    else {
        // Just select this method
        self.selectedPaymentMethod = paymentMethod;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationFade];
        [self.delegate internalViewControllerDidSelectPaymentMethod:paymentMethod];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    }
    return 27.0f;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    BOOL showingSavedSection = [self tableView:tableView numberOfRowsInSection:STPPaymentMethodSavedPaymentsSection] > 0;
    CGSize fittingSize = CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX);
    NSInteger numberOfRows = [self tableView:tableView numberOfRowsInSection:section];
    if (section == STPPaymentMethodNewPaymentsSection && numberOfRows != 0 && showingSavedSection) {
        return [self.moreSectionHeaderView sizeThatFits:fittingSize].height;
    }
    return 0.01f;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    BOOL showingSavedSection = [self tableView:tableView numberOfRowsInSection:STPPaymentMethodSavedPaymentsSection] > 0;
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return [UIView new];
    } else if (section == STPPaymentMethodNewPaymentsSection && showingSavedSection) {
        return self.moreSectionHeaderView;
    }
    return nil;
}

- (void)updateWithPaymentMethodTuple:(STPPaymentMethodTuple *)tuple {
    if ([self.savedPaymentMethods isEqualToArray:tuple.savedPaymentMethods]
        && [self.availablePaymentTypes isEqualToArray:tuple.availablePaymentTypes]
        && [self.selectedPaymentMethod isEqual:tuple.selectedPaymentMethod]) {
        return;
    }
    self.savedPaymentMethods = tuple.savedPaymentMethods;
    self.availablePaymentTypes = tuple.availablePaymentTypes;
    self.selectedPaymentMethod = tuple.selectedPaymentMethod;

    NSMutableIndexSet *sections = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.tableView numberOfSections])];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion {
    [self.delegate internalViewControllerDidCreateTokenOrSource:token
                                                     completion:completion];
}

- (void)addSourceViewControllerDidCancel:(__unused STPAddSourceViewController *)addSourceViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addSourceViewController:(__unused STPAddSourceViewController *)addSourceViewController
                didCreateSource:(STPSource *)source
                     completion:(STPErrorBlock)completion {
    [self.delegate internalViewControllerDidCreateTokenOrSource:source
                                                     completion:completion];
}

@end
