//
//  SwiftySnapResourcesBundleProvider.swift
//  SwiftySnap
//
//  Created by DREAMWORLD on 23/05/25.
//

import Foundation

public enum SwiftySnapResourcesBundleProvider {
    public static var bundle: Bundle {
        // Use this if you are using CocoaPods
        let bundleName = "SwiftySnap"

        let candidates = [
            // Bundle should be present in the main bundle if linked directly
            Bundle.main.resourceURL,
            // Look in the bundle of this class if part of a framework
            Bundle(for: SwiftySnapResourcesBundleProviderClass.self).resourceURL,
            // Sometimes resources are nested inside a sub-bundle with the same name
            Bundle(for: SwiftySnapResourcesBundleProviderClass.self).resourceURL?.appendingPathComponent(bundleName + ".bundle")
        ]

        for candidate in candidates {
            if let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle"),
               let bundle = Bundle(url: bundlePath) {
                return bundle
            }
        }

        return Bundle.main
    }
}

private class SwiftySnapResourcesBundleProviderClass {}
