Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '21.6.0'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '11.0'
  s.swift_version		               = '5.0'
  s.default_subspec = 'Full'
  s.subspec 'Full' do |fs|
    fs.resource_bundle           = { 'Stripe' => 'Stripe/Resources/**/*.{lproj,json,png,xcassets}' }
    fs.source_files                   = 'Stripe/*.swift', 'Stripe/PanModal/**/*.swift'
    fs.subspec 'Stripe3DS2' do |sp|
      sp.source_files  = 'Stripe3DS2/Stripe3DS2/**/*.{h,m}'
      sp.resource_bundles = { 'Stripe3DS2' => ['Stripe3DS2/Stripe3DS2/Resources/**/*.{lproj,png}'] }
    end  
  end
  s.subspec 'Min' do |ms|
    ms.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-DSTRIPE_MIN_SDK',
                               'SWIFT_OPTIMIZATION_LEVEL' => '-Osize' }
    ms.resource_bundles           = { 'Stripe' => ['Stripe/Resources/**/*.{lproj}', 'Stripe/Resources/Images/Cards/*.{png}'] }
    ms.source_files                   = 'Stripe/*.swift'
    ms.exclude_files = ['Stripe/STPThreeDS*.swift',
      'Stripe/*TableViewCell.swift',
      'Stripe/Card*.swift',
      'Stripe/Circular*.swift',
      'Stripe/Payment*.swift',
      'Stripe/Payment*.swift',
      'Stripe/After*.swift',
      'Stripe/STP3DS2AuthenticateResponse.swift',
      'Stripe/SavedPaymentMethod*.swift',
      'Stripe/ApplePay*.swift',
      'Stripe/Alipay*.swift',
      'Stripe/Billing*.swift',
      'Stripe/Ideal*.swift',
      'Stripe/Checkbox*.swift',
      'Stripe/Confirm*.swift',
      'Stripe/Shadowed*.swift',
      'Stripe/Sheet*.swift',
      'Stripe/*+PaymentSheet.swift',
      'Stripe/Saved*.swift',
      'Stripe/Loading*.swift',
      'Stripe/Bottom*.swift',
      'Stripe/STPCardForm*.swift',
      'Stripe/STPiDEALForm*.swift',
      'Stripe/STPMultiFormTextField.swift',
      'Stripe/STPLabeledFormTextFieldView.swift',
      'Stripe/STPLabeledMultiFormTextFieldView.swift',
      'Stripe/STPFormTextFieldContainer.swift',
      'Stripe/STPAUBECSDebitFormView.swift',
      'Stripe/*ViewController.swift',
      'Stripe/STPPaymentCardTextFieldCell.swift',
      'Stripe/STPPaymentActivityIndicatorView.swift',
      'Stripe/STPSectionHeaderView.swift',
      'Stripe/STPCardScanner.swift',
      'Stripe/STPCardScannerTableViewCell.swift',
      'Stripe/STPCardParams.swift',
      'Stripe/STPCameraView.swift',
      'Stripe/STPUserInformation.swift',
      'Stripe/STPPaymentContex*.swift',
      'Stripe/UITableViewCell+Stripe_Borders.swift',
      'Stripe/UIBarButtonItem+Stripe.swift',
      'Stripe/UINavigationBar+Stripe_Theme.swift',
      'Stripe/STPTheme.swift',
      'Stripe/STPAddressViewModel.swift',
      'Stripe/STPAUBECSFormViewModel.swift',
      'Stripe/STPSource.swift',
      'Stripe/STPSourcePoller.swift',
      'Stripe/STPSourceParams.swift',
      'Stripe/STPSourceWeChatPayDetails.swift',
      'Stripe/STPSourceOwner.swift',
      'Stripe/STPSourceEnums.swift',
      'Stripe/STPSourceR*.swift',
      'Stripe/STPSourceVerification.swift',
      'Stripe/STPSourceCardDetails.swift',
      'Stripe/STPSourceKlarnaDetails.swift',
      'Stripe/STPMultipart*.swift',
      'Stripe/STPSourceSEPA*.swift',
      'Stripe/STPCustome*.swift',
      'Stripe/STPBackendAPIAdapter.swift',
      'Stripe/STPBankAccount.swift',
      'Stripe/STPBankAccountParams.swift',
      'Stripe/STPPaymentMethodOXX*.swift',
      'Stripe/STPPaymentMethodPayPa*.swift',
      'Stripe/STPKlarna*.swift',
      'Stripe/STPPushProvisioning*.swift',
      'Stripe/STPPaymentMethodUP*.swift',
      'Stripe/STPPaymentMethodNetBankin*.swift',
      'Stripe/STPPaymentMethodAli*.swift',
      'Stripe/STPPaymentMethodAUBECS*.swift',
      'Stripe/STPPaymentMethodBacs*.swift',
      'Stripe/STPPaymentMethodBancontac*.swift',
      'Stripe/STPPaymentMethodEP*.swift',
      'Stripe/STPPaymentMethodFP*.swift',
      'Stripe/STPPaymentMethodGiro*.swift',
      'Stripe/STPPaymentMethodGrab*.swift',
      'Stripe/STPPaymentMethodPrzel*.swift',
      'Stripe/STPPaymentMethodSEPA*.swift',
      'Stripe/STPPaymentMethodSofor*.swift',
      'Stripe/STPPaymentMethodiDEA*.swift',
      'Stripe/STPRedirectContext.swift',
      'Stripe/STPAPIClient+PushProvisioning.swift',
      'Stripe/PKAddPaymentPassRequest+Stripe_Error.swift',
      'Stripe/STPFPX*.swift',
      'Stripe/STPIntentActionOXXO*.swift',
      'Stripe/STPPaymentOptionTuple.swift',
      'Stripe/STPEmailAddressValidator.swift',
      'Stripe/STPBECSDebitAccountNumberValidator.swift',
      'Stripe/STPBSBNumberValidator.swift',
      'Stripe/UINavigationController+Stripe_Completion.swift',
      'Stripe/UIView+Stripe_SafeAreaBounds.swift',
      'Stripe/UIView+STPIntentActionAlipayHandleRedirect.swift',
      'Stripe/STPIssuingCardPin.swift',
      'Stripe/STPConfirmAlipayOptions.swift',
      'Stripe/STPApplePayPaymentOption.swift',
      'Stripe/STPEphemeralKey.swift',
      'Stripe/STPEphemeralKeyManager.swift',
      'Stripe/STPMandate*.swift',
      'Stripe/STPConnect*.swift',
      'Stripe/STPFile.swift',
      'Stripe/STPPinManagementService.swift',
      'Stripe/UIViewController+Stripe_NavigationItemProxy.swift',
      'Stripe/UIImage+Stripe.swift',
      'Stripe/UIViewController+Stripe_KeyboardAvoiding.swift']
    end
end
