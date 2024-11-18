//
//  ActivityViewControllerWithoutPopover.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/15/24.
//

import UIKit

/// A `UIActivityViewController` that always uses a `formSheet` modalPresentationStyle.
/// This prevents the presentation style from getting set to `popup` on iPad.
class FormSheetActivityViewController: UIActivityViewController {
    /*
     Setting `modalPresentationStyle` directly after instantiating a
     UIActivityViewController doesn't work because UIKit overrides it.
     So we have to subclass and override `modalPresentationStyle`.
     */
    override var modalPresentationStyle: UIModalPresentationStyle {
        get { .formSheet }
        set { }
    }
}
