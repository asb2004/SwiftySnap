
![alt text](https://github.com/asb2004/SwiftySnap/blob/main/SwiftySnapView.jpg)

# SwiftySnap 📸

**SwiftySnap** is a customizable, full-screen camera view for iOS — built with Swift. It supports photo and video capture, pinch-to-zoom, flash, camera switching, and custom UI design via XIB.

## ✨ Features

- 📷 Full-screen custom camera (`SwiftySnapViewController.xib` is editable)
- 💡 Flash support
- 🎞️ Photo, Video, or Both modes
- ⏱ Video duration limit
- 🔄 Front and Back camera
- 🤏 Pinch to zoom (from **0.5x (Ultra Wide)** to **5x**)

---

## 📦 Installation

### Swift Package Manager (SPM)

Add the following URL to your **Xcode** project's **Package Dependencies**:

https://github.com/asb2004/SwiftySnap.git

---

## Requirements

- iOS 13.0+

---

## 🚀 Getting Started

### 1. Import the module

```swift
import SwiftySnap
```

### 2. Present the camera

```swift
let vc = SwiftySnapViewController()
vc.modalTransitionStyle = .crossDissolve
vc.modalPresentationStyle = .fullScreen
vc.delegate = self
self.present(vc, animated: true)
```

### 🎨 Customize Colors

```swift
struct CustomColor: SwiftySnapColorProviding {
    var primaryColor: UIColor { .purple }
}

SwiftySnapColorManager.provider = CustomColor()
```

### ⚙️ Configuration

Camera Type

```swift
vc.CameraType = .Photo // or .Video / .Both
```

Video Recording Duration (in seconds)

```swift
vc.maxRecordingDuration = 60
```

### 🎯 Delegate Methods

```swift
extension YourViewController: SwiftySnapDelegate {
    func cameraDidCapturePhoto(_ image: UIImage) {
        // Called when a photo is captured
    }

    func cameraDidCaptureVideo(url: URL) {
        // Called when video is recorded
    }

    func cameraDidCancel() {
        // Called when camera is dismissed without capturing
    }
}
```

### 🪄 Custom UI

Want to change the layout or style?

Edit the SwiftySnapViewController.xib file inside the module for full design control.

