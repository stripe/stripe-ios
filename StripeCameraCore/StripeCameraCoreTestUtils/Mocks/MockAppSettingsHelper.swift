//
//  MockAppSettingsHelper.swift
//  StripeCameraCoreTestUtils
//
//  Created by Mel Ludowise on 12/3/21.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore

@_spi(InternalOnlyAPI) public class MockAppSettingsHelper: AppSettingsHelperProtocol {

    public var canOpenAppSettings = false
    public private(set) var didOpenAppSettings = false

    public init() {}

    public func openAppSettings() {
        didOpenAppSettings = true
    }
}
