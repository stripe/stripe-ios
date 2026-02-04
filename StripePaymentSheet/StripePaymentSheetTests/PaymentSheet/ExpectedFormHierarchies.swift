//
//  ExpectedFormHierarchies.swift
//  StripePaymentSheetTests
//
//  Expected form hierarchies for LPM confirm flow tests.
//  Each payment method has separate expected hierarchies for different intent types.
//

import Foundation

/// Expected form hierarchies for LPM confirm flow tests.
/// Organized by payment method, with separate static properties for different intent types.
enum ExpectedFormHierarchy {

    // MARK: - Simple Empty Forms (no input fields)

    /// Payment methods with empty forms (just FormElement, no children)
    static var emptyForm: FormHierarchyNode {
        FormHierarchyNode(type: "FormElement")
    }

    /// Payment methods that show only a mandate when setting up for future use
    static var formWithMandateOnly: FormHierarchyNode {
        FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SimpleMandateElement", properties: ["text": "By providing your payment information and confirmi..."])
        ])
    }

    // MARK: - GrabPay

    enum GrabPay {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Alipay

    enum Alipay {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - PayNow

    enum PayNow {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Swish

    enum Swish {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - MobilePay

    enum MobilePay {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Twint

    enum Twint {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Zip

    enum Zip {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Crypto

    enum Crypto {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Alma

    enum Alma {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Sunbit

    enum Sunbit {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Billie

    enum Billie {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - PayPay

    enum PayPay {
        static var paymentIntent: FormHierarchyNode { emptyForm }
    }

    // MARK: - Amazon Pay

    enum AmazonPay {
        static var paymentIntent: FormHierarchyNode { emptyForm }
        static var settingUp: FormHierarchyNode { formWithMandateOnly }
    }

    // MARK: - CashApp

    enum CashApp {
        static var paymentIntent: FormHierarchyNode { emptyForm }
        static var settingUp: FormHierarchyNode { formWithMandateOnly }
    }

    // MARK: - PayPal

    enum PayPal {
        static var paymentIntent: FormHierarchyNode { emptyForm }
        static var settingUp: FormHierarchyNode { formWithMandateOnly }
    }

    // MARK: - RevolutPay

    enum RevolutPay {
        static var paymentIntent: FormHierarchyNode { emptyForm }
        static var settingUp: FormHierarchyNode { formWithMandateOnly }
    }

    // MARK: - Satispay

    enum Satispay {
        static var paymentIntent: FormHierarchyNode { emptyForm }
        static var settingUp: FormHierarchyNode { formWithMandateOnly }
    }

    // MARK: - FPX

    enum FPX {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "18", "label": "FPX Bank"])
                ]),
            ])
        }
    }

    // MARK: - BLIK

    enum BLIK {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "BLIK code"])
                ]),
            ])
        }
    }

    // MARK: - EPS

    enum EPS {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"])
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "27", "label": "EPS Bank"])
                ]),
            ])
        }
    }

    // MARK: - Przelewy24

    enum Przelewy24 {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "23", "label": "Przelewy24 Bank"])
                ]),
            ])
        }
    }

    // MARK: - Affirm

    enum Affirm {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SubtitleElement")
            ])
        }
    }

    // MARK: - Bancontact

    enum Bancontact {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"])
                ]),
            ])
        }

        static var settingUp: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "SimpleMandateElement", properties: ["text": "By providing your payment information and confirmi..."]),
            ])
        }
    }

    // MARK: - iDEAL

    enum iDEAL {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"])
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "13", "label": "iDEAL Bank"])
                ]),
            ])
        }

        static var settingUp: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "13", "label": "iDEAL Bank"])
                ]),
                FormHierarchyNode(type: "SimpleMandateElement", properties: ["text": "By providing your payment information and confirmi..."]),
            ])
        }
    }

    // MARK: - Klarna

    enum Klarna {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SubtitleElement"),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"])
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "235", "label": "Country or region"])
                ]),
            ])
        }

        static var settingUp: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SubtitleElement"),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"])
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "235", "label": "Country or region"])
                ]),
                FormHierarchyNode(type: "SimpleMandateElement", properties: ["text": "By providing your payment information and confirmi..."]),
            ])
        }
    }

    // MARK: - Multibanco

    enum Multibanco {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"])
                ]),
            ])
        }
    }

    // MARK: - PromptPay

    enum PromptPay {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"])
                ]),
            ])
        }
    }

    // MARK: - OXXO

    enum OXXO {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
            ])
        }
    }

    // MARK: - Konbini

    enum Konbini {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Phone number"])
                ]),
            ])
        }
    }

    // MARK: - AU BECS Debit

    enum AUBECSDebit {
        static var all: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Name on account"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "BSB number"])
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Account number"])
                ]),
                FormHierarchyNode(type: "StaticElement", properties: ["viewType": "AUBECSLegalTermsView"]),
            ])
        }
    }

    // MARK: - SEPA Debit

    enum SEPADebit {
        static var all: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "IBAN"])
                ]),
                FormHierarchyNode(type: "AddressSectionElement", children: [
                    FormHierarchyNode(type: "SectionElement", properties: ["title": "Billing address"], children: [
                        FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "235", "label": "Country or region"]),
                        FormHierarchyNode(type: "DummyAddressLine"),
                    ]),
                    FormHierarchyNode(type: "CheckboxElement", properties: ["label": "Billing address is same as shipping"]),
                ]),
                FormHierarchyNode(type: "SimpleMandateElement", properties: ["text": "By providing your payment information and confirmi..."]),
            ])
        }
    }

    // MARK: - Bacs Debit

    enum BacsDebit {
        static var all: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Bank account"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Sort code"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Account number"]),
                ]),
                FormHierarchyNode(type: "AddressSectionElement", children: [
                    FormHierarchyNode(type: "SectionElement", properties: ["title": "Billing address"], children: [
                        FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "235", "label": "Country or region"]),
                        FormHierarchyNode(type: "DummyAddressLine"),
                    ]),
                    FormHierarchyNode(type: "CheckboxElement", properties: ["label": "Billing address is same as shipping"]),
                ]),
                FormHierarchyNode(type: "CheckboxElement", properties: ["label": "I understand that Stripe will be collecting Direct Debits on behalf of StripePaymentSheetTestHostApp and confirm that I am the account holder and the only person required to authorise debits from this account."]),
            ])
        }
    }

    // MARK: - Boleto

    enum Boleto {
        static var all: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "CPF/CPNJ"])
                ]),
                FormHierarchyNode(type: "AddressSectionElement", children: [
                    FormHierarchyNode(type: "SectionElement", properties: ["title": "Billing address"], children: [
                        FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "1", "label": "Country or region"]),
                        FormHierarchyNode(type: "DummyAddressLine"),
                    ]),
                    FormHierarchyNode(type: "CheckboxElement", properties: ["label": "Billing address is same as shipping"]),
                ]),
            ])
        }
    }

    // MARK: - Afterpay

    enum Afterpay {
        static var paymentIntent: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SubtitleElement"),
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
                ]),
                FormHierarchyNode(type: "AddressSectionElement", children: [
                    FormHierarchyNode(type: "SectionElement", properties: ["title": "Billing address"], children: [
                        FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "235", "label": "Country or region"]),
                        FormHierarchyNode(type: "DummyAddressLine"),
                    ]),
                    FormHierarchyNode(type: "CheckboxElement", properties: ["label": "Billing address is same as shipping"]),
                ]),
            ])
        }
    }

    // MARK: - Card

    enum Card {
        static var minimalBilling: FormHierarchyNode {
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "CardSectionElement", children: [
                    FormHierarchyNode(type: "SectionElement", children: [
                        FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Card number"]),
                        FormHierarchyNode(type: "MultiElementRow", children: [
                            FormHierarchyNode(type: "TextFieldElement", properties: ["label": "MM / YY"]),
                            FormHierarchyNode(type: "TextFieldElement", properties: ["label": "CVC"]),
                        ]),
                    ]),
                ]),
            ])
        }
    }
}
