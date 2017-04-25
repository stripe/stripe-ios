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
#import "STPColorUtils.h"
#import "STPCoreTableViewController+Private.h"
#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethodTableViewCell.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UITableViewCell+Stripe_Borders.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";
static NSInteger STPPaymentMethodCardListSection = 0;
static NSInteger STPPaymentMethodAddCardSection = 1;

@interface STPPaymentMethodsInternalViewController()<UITableViewDataSource, UITableViewDelegate, STPAddCardViewControllerDelegate>

@property(nonatomic)STPPaymentConfiguration *configuration;
@property(nonatomic)STPUserInformation *prefilledInformation;
@property(nonatomic)STPAddress *shippingAddress;
@property(nonatomic)NSArray<id<STPPaymentMethod>> *paymentMethods;
@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic, weak)id<STPPaymentMethodsInternalViewControllerDelegate> delegate;
@property(nonatomic, weak)UIImageView *cardImageView;

@end

@implementation STPPaymentMethodsInternalViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme
                 prefilledInformation:(STPUserInformation *)prefilledInformation
                      shippingAddress:(STPAddress *)shippingAddress
                   paymentMethodTuple:(STPPaymentMethodTuple *)tuple
                             delegate:(id<STPPaymentMethodsInternalViewControllerDelegate>)delegate {
    self = [super initWithTheme:theme];
    if (self) {
        _configuration = configuration;
        _prefilledInformation = prefilledInformation;
        _shippingAddress = shippingAddress;
        _paymentMethods = tuple.paymentMethods;
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
    
    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[STPImageLibrary largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    cardImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, cardImageView.bounds.size.height + (57 * 2));
    self.cardImageView = cardImageView;
    self.tableView.tableHeaderView = cardImageView;
    
    self.cardImageView.image = [STPImageLibrary largeCardFrontImage];

    self.cardImageView.tintColor = self.theme.accentColor;
}

- (void)handleBackOrCancelTapped:(__unused id)sender {
    [self.delegate internalViewControllerDidCancel];
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentMethodCardListSection) {
        return self.paymentMethods.count;
    } else if (section == STPPaymentMethodAddCardSection) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPPaymentMethodTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = [self.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
        [cell configureWithPaymentMethod:paymentMethod theme:self.theme];
        cell.selected = [paymentMethod isEqual:self.selectedPaymentMethod];
    } else {
        [cell configureForNewCardRowWithTheme:self.theme];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = [self.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
        self.selectedPaymentMethod = paymentMethod;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:STPPaymentMethodCardListSection] withRowAnimation:UITableViewRowAnimationFade];
        [self.delegate internalViewControllerDidSelectPaymentMethod:paymentMethod];
    } else if (indexPath.section == STPPaymentMethodAddCardSection) {
        STPPaymentConfiguration *config = [self.configuration copy];
        NSArray *cardPaymentMethods = [self.paymentMethods filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<STPPaymentMethod> paymentMethod, __unused NSDictionary<NSString *,id> * _Nullable bindings) {
            return [paymentMethod isKindOfClass:[STPCard class]];
        }]];
        // Disable SMS autofill if we already have a card on file
        config.ineligibleForSmsAutofill = (cardPaymentMethods.count > 0);
        
        STPAddCardViewController *paymentCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:config theme:self.theme];
        paymentCardViewController.delegate = self;
        paymentCardViewController.prefilledInformation = self.prefilledInformation;
        paymentCardViewController.shippingAddress = self.shippingAddress;
        [self.navigationController pushViewController:paymentCardViewController animated:YES];
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
    return 0.01f;
}

- (void)updateWithPaymentMethodTuple:(STPPaymentMethodTuple *)tuple {
    if ([self.paymentMethods isEqualToArray:tuple.paymentMethods] &&
        [self.selectedPaymentMethod isEqual:tuple.selectedPaymentMethod]) {
        return;
    }
    self.paymentMethods = tuple.paymentMethods;
    self.selectedPaymentMethod = tuple.selectedPaymentMethod;
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSetWithIndex:STPPaymentMethodCardListSection];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion {
    [self.delegate internalViewControllerDidCreateToken:token completion:completion];
}

@end
