//
//  SwiftySnapView.swift
//  SwiftySnap
//
//  Created by DREAMWORLD on 22/05/25.
//

import UIKit

public protocol SwiftySnapDelegate: AnyObject {
    func cameraDidCapturePhoto(_ image: UIImage)
    func cameraDidCaptureVideo(url: URL)
    func cameraDidCancel()
}
