Pod::Spec.new do |s|
  s.name             = 'SwiftySnap'
  s.version          = '1.0.0'
  s.summary          = 'SwiftySnap - Swift Package for Custom camera'
  s.description      = <<-DESC
    SwiftySnap is a customizable, full-screen camera view for iOS — built with Swift. It supports photo and video capture, pinch-to-zoom, flash, camera switching, and custom UI design via XIB.
    It supports snapping photos with a clean and extendable architecture using UIKit.
  DESC
  s.homepage         = 'https://github.com/asb2004/SwiftySnap'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'abhi2004-ios' => 'babriyaabhi@gmail.com' }
  s.source           = { :git => 'https://github.com/asb2004/SwiftySnap.git', :tag => s.version.to_s }

  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'

  s.source_files     = 'Sources/SwiftySnap/**/*.{swift}'

  s.resource_bundles = {
    'SwiftySnapResources' => [
      'Sources/SwiftySnap/Camera View/View/SwiftySnapViewController.xib',
      'Sources/SwiftySnap/Assets/Media.xcassets',
      'Sources/SwiftySnap/Resources/**/*'
    ]
  }
end
