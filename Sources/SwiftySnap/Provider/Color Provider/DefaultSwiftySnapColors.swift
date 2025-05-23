//
//  DefaultSwiftySnapColors.swift
//  SwiftySnap
//
//  Created by DREAMWORLD on 22/05/25.
//

import UIKit

public struct DefaultSwiftySnapColors: SwiftySnapColorProviding {
    public init() {}

    public var primaryColor: UIColor {
        UIColor(named: "app_primary_color", in: SwiftySnapResourcesBundleProvider.bundle, compatibleWith: nil) ?? .systemBlue
    }
}
