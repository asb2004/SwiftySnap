//
//  SwiftySnapViewController.swift
//  SwiftySnap
//
//  Created by DREAMWORLD on 22/05/25.
//

import UIKit
import AVFoundation

public class SwiftySnapViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var btnUltraWideAngle: UIButton!
    @IBOutlet weak var btnWideAngle: UIButton!
    @IBOutlet weak var btnVideo: UIButton!
    @IBOutlet weak var btnPhoto: UIButton!
    @IBOutlet weak var btnClose: UIButton!

    @IBOutlet weak var btnShutter: UIImageView!
    @IBOutlet weak var btnFlipCamera: UIImageView!
    @IBOutlet weak var btnFlash: UIImageView!

    @IBOutlet weak var lblRecordingTime: UILabel!
    @IBOutlet weak var previewView: UIView!

    // MARK: - Properties
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var photoOutput = AVCapturePhotoOutput()
    var movieOutput = AVCaptureMovieFileOutput()
    var activeCamera: AVCaptureDevice?

    var currentFlashMode: AVCaptureDevice.FlashMode = .off

    var outputURL: URL?
    var isRecording = false
    var recordingTimer: Timer?
    var recordingStartTime: Date?
    
    ///Set Video Capture Duration, By Default it is 15
    public var maxRecordingDuration: TimeInterval = 15
    var stopRecordingTask: DispatchWorkItem?

    var isPhoto = true

    var currentZoomFactor: CGFloat = 1.0
    
    public var CameraType: SwiftySnapCameraType = .Both
    
    ///Confirm SwiftySnapDelegate to Retrive Captured Photo and Video
    public var delegate: SwiftySnapDelegate?

    //MARK: - View Life Cycle Methods
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "SwiftySnapViewController", bundle: Bundle.module)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadViewFromNib()
    }
    
    private func loadViewFromNib() {
        let bundle = Bundle.module
        let nib = UINib(nibName: "SwiftySnapViewController", bundle: bundle)
        nib.instantiate(withOwner: self, options: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.videoPreviewLayer?.frame = self.previewView.bounds
        self.view.layoutIfNeeded()
    }

    // MARK: - Button Action
    @IBAction func closeCamera() {
        self.dismiss(animated: true) {
            self.delegate?.cameraDidCancel()
        }
    }

    @IBAction func btnPhotoAction(_ sender: UIButton) {
        self.btnWideAngleAction(UIButton())
        updateModeButtons(photoActive: true)
    }

    @IBAction func btnVideoAction(_ sender: UIButton) {
        self.btnWideAngleAction(UIButton())
        updateModeButtons(photoActive: false)
    }

    @IBAction func btnUltraWideAngleAction(_ sender: Any) {
        updateZoomButtons(ultraWideActive: true)
        setZoom(factor: 0.5)
    }

    @IBAction func btnWideAngleAction(_ sender: Any) {
        updateZoomButtons(ultraWideActive: false)
        setZoom(factor: 1.0)
    }
}

//MARK: - Obj C Methods
extension SwiftySnapViewController {

    @objc func shutterTapped() {
        if isPhoto {
            capturePhoto()
        } else {
            toggleVideoRecording()
        }
    }

    @objc func flipCameraTapped() {
        flipCamera()
    }

    @objc func flashTapped() {
        toggleFlash()
    }

    // MARK: - Pinch Gesture Handler
    @objc private func handlePinchToZoom(_ pinch: UIPinchGestureRecognizer) {
        guard let device = activeCamera else {
            print("Pinch failed: No device")
            return
        }

        // Define min and max logical zoom based on the device type
        let minZoom: CGFloat = device.position == .back ? hasUltraWideCamera() ? 0.5 : 1.0 : device.minAvailableVideoZoomFactor
        let maxZoom: CGFloat = 5.0 //device.maxAvailableVideoZoomFactor

        switch pinch.state {
        case .began, .changed:
            let newScale = currentZoomFactor * pinch.scale
            let clampedScale = min(max(newScale, minZoom), maxZoom)
            setZoom(factor: clampedScale, animated: false)
            pinch.scale = 1.0
            self.updateZoomButtonsForCurrentZoomLevel()

        case .ended:
            self.setZoom(factor: currentZoomFactor, animated: true)
            self.updateZoomButtonsForCurrentZoomLevel()
        default:
            break
        }
    }
}

//MARK: - All Methods
extension SwiftySnapViewController {

    func setupUI() {
        
        self.btnPhoto.isHidden = true
        self.btnVideo.isHidden = true
        
        switch CameraType {
        case .Photo:
            isPhoto = true
            self.btnPhoto.isHidden = false
        case.Video:
            isPhoto = false
            self.btnVideo.isHidden = false
        case .Both:
            isPhoto = true
            self.btnPhoto.isHidden = false
            self.btnVideo.isHidden = false
        }

        self.btnUltraWideAngle.superview?.superview?.isHidden = !(hasUltraWideCamera())
        self.btnUltraWideAngle.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        self.btnWideAngle.setTitleColor(SwiftySnapColorManager.provider.primaryColor, for: .normal)
        
        btnPhoto.setTitleColor(isPhoto ? SwiftySnapColorManager.provider.primaryColor : .systemGray, for: .normal)
        btnVideo.setTitleColor(isPhoto ? .systemGray : SwiftySnapColorManager.provider.primaryColor, for: .normal)

        setupCamera()
        addGestures()
    }

    func addGestures() {
        let shutterTap = UITapGestureRecognizer(target: self, action: #selector(shutterTapped))
        btnShutter.addGestureRecognizer(shutterTap)

        let flipTap = UITapGestureRecognizer(target: self, action: #selector(flipCameraTapped))
        btnFlipCamera.addGestureRecognizer(flipTap)

        let flashTap = UITapGestureRecognizer(target: self, action: #selector(flashTapped))
        btnFlash.addGestureRecognizer(flashTap)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchToZoom))
        previewView.addGestureRecognizer(pinchGesture)
        previewView.isUserInteractionEnabled = true
    }

    private func updateModeButtons(photoActive: Bool) {
        resetFlash()
        btnPhoto.setTitleColor(photoActive ? SwiftySnapColorManager.provider.primaryColor : .systemGray, for: .normal)
        btnVideo.setTitleColor(photoActive ? .systemGray : SwiftySnapColorManager.provider.primaryColor, for: .normal)
        isPhoto = photoActive
    }

    private func updateZoomButtons(ultraWideActive: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.btnUltraWideAngle.transform = ultraWideActive ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.btnWideAngle.transform = ultraWideActive ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity

            self.btnUltraWideAngle.setTitleColor(ultraWideActive ? SwiftySnapColorManager.provider.primaryColor : .white, for: .normal)
            self.btnWideAngle.setTitleColor(ultraWideActive ? .white : SwiftySnapColorManager.provider.primaryColor, for: .normal)

            self.btnUltraWideAngle.setTitle(ultraWideActive ? "0.5x" : "0.5", for: .normal)
            self.btnWideAngle.setTitle(ultraWideActive ? "1" : "1x", for: .normal)
        }
    }

    private func updateZoomButtonsForCurrentZoomLevel() {
        let roundedNumber = Double(String(format: "%.1f", currentZoomFactor))!
        let ultraWideActive = roundedNumber < 1.0
        let wideAngleActive = roundedNumber >= 1.0 && roundedNumber <= 5.0

        UIView.animate(withDuration: 0.3) {
            self.btnUltraWideAngle.transform = ultraWideActive ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.btnWideAngle.transform = wideAngleActive ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)

            self.btnUltraWideAngle.setTitleColor(ultraWideActive ? SwiftySnapColorManager.provider.primaryColor : .white, for: .normal)
            self.btnWideAngle.setTitleColor(wideAngleActive ? SwiftySnapColorManager.provider.primaryColor : .white, for: .normal)

            self.btnUltraWideAngle.setTitle(ultraWideActive ? "\(roundedNumber)x" : "0.5", for: .normal)
            self.btnWideAngle.setTitle(wideAngleActive ? "\(roundedNumber)x" : "1", for: .normal)
        }
    }

    // MARK: - Camera Setup
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        // Explicitly find builtInDualWideCamera
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualWideCamera],
            mediaType: .video,
            position: .back
        )

        if let device = discoverySession.devices.first {
            activeCamera = device
            configureCameraInput(device: device)
        } else {
            print("Dual wide camera not found, falling back to wide")
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                activeCamera = device
                configureCameraInput(device: device)            }
        }

        // Setup preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = previewView.frame
        previewView.layer.addSublayer(videoPreviewLayer!)

        // Start Session
        captureSession?.startRunning()
    }

    func configureCameraInput(device: AVCaptureDevice) {
        do {
            captureSession?.beginConfiguration()
            captureSession?.inputs.forEach { captureSession?.removeInput($0) }

            let input = try AVCaptureDeviceInput(device: device)
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }

            // Set up audio input
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                print("No audio device available")
                return
            }

            guard let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
                print("Unable to access audio input")
                return
            }

            if captureSession?.canAddInput(audioInput) == true{
                captureSession?.addInput(audioInput)
            }

            // Add Photo Output
            if captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            }

            // Add Video Output
            if captureSession?.canAddOutput(movieOutput) == true {
                captureSession?.addOutput(movieOutput)
            }

            if hasUltraWideCamera() && activeCamera?.position == .back {
                setZoom(factor: 1.0, animated: false)
            }

            captureSession?.commitConfiguration()
        } catch {
            print("Error configuring camera: \(error.localizedDescription)")
        }
    }

    func resetFlash() {
        currentFlashMode = .off
        btnFlash.tintColor = .white
        if let device = activeCamera, device.hasTorch {
            try? device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        }
    }

    // MARK: - Zoom Functionality
    func setZoom(factor: CGFloat, animated: Bool = true) {
        guard let device = activeCamera else { return }

        do {
            try device.lockForConfiguration()
            let minZoom = device.minAvailableVideoZoomFactor // 1.0 (ultra-wide)
            let maxZoom = device.maxAvailableVideoZoomFactor // 123.75

            // Map logical zoom to device zoom
            let deviceZoom: CGFloat
            if hasUltraWideCamera() && device.position == .back {
                if factor <= 0.5 {
                    deviceZoom = 1.0 // Ultra-wide
                } else if factor <= 1.0 {
                    deviceZoom = 1.0 + (factor - 0.5) * 2.0
                } else {
                    deviceZoom = 2.0 + (factor - 1.0) * 2.0
                }
            } else {
                // Wide-angle only: 1.0x and up
                deviceZoom = max(minZoom, min(factor, maxZoom))
            }

            let targetZoom = max(minZoom, min(deviceZoom, maxZoom))
            currentZoomFactor = factor

            // Calculate the estimated animation duration based on current zoom and target zoom.
            let currentZoom = device.videoZoomFactor
            let delta = abs(targetZoom - currentZoom)
            let animationDuration = delta / 4.0

            if animated {
                self.btnShutter.isUserInteractionEnabled = false
                // Animate the zoom transition
                device.ramp(toVideoZoomFactor: targetZoom, withRate: 4.0)

                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                    self.btnShutter.isUserInteractionEnabled = true
                }
            } else {
                device.videoZoomFactor = targetZoom
            }

            device.unlockForConfiguration()        } catch {
            print("Error setting zoom: \(error.localizedDescription)")
        }
    }

    // MARK: - Capture Photo
    func capturePhoto() {
        self.btnShutter.isUserInteractionEnabled = false
        let settings = AVCapturePhotoSettings()
        settings.flashMode = currentFlashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Start/Stop Video Recording
    func toggleVideoRecording() {
        if isRecording {
            self.btnPhoto.superview?.isHidden = false
            self.btnShutter.isUserInteractionEnabled = false
            stopRecording()
        } else {
            self.btnPhoto.superview?.isHidden = true
            startRecording()
        }
    }

    func startRecording() {

        if let videoConnection = movieOutput.connection(with: .video) {
            videoConnection.isVideoMirrored = (activeCamera?.position == .front) ? true : false
        }

        guard let outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let filePath = outputDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        outputURL = filePath

        movieOutput.startRecording(to: filePath, recordingDelegate: self)
        isRecording = true
        btnPhoto.isHidden = true
        btnFlipCamera.isHidden = true

        recordingStartTime = Date()
        // Start updating recording time
        lblRecordingTime.superview?.isHidden = false
        btnShutter.tintColor = .systemRed
        lblRecordingTime.text = "00:00"
        startRecordingTimer()

        // Schedule automatic stop after 15 seconds
        stopRecordingTask = DispatchWorkItem { [weak self] in
            self?.stopRecording()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + maxRecordingDuration, execute: stopRecordingTask!)
    }

    func stopRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        isRecording = false
        btnPhoto.isHidden = false
        btnFlipCamera.isHidden = false

        // Stop Timer & Hide Recording Time
        recordingTimer?.invalidate()
        recordingTimer = nil
        btnShutter.tintColor = .white
        lblRecordingTime.superview?.isHidden = true

        // Cancel the scheduled stop task
        stopRecordingTask?.cancel()

        self.resetFlash()
    }

    // Timer to update recording duration
    func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard let startTime = self.recordingStartTime else { return }
                let elapsedTime = Int(Date().timeIntervalSince(startTime))
                
                // Format the time as MM:SS
                let minutes = elapsedTime / 60
                let seconds = elapsedTime % 60
                self.lblRecordingTime.text = String(format: "%02d:%02d", minutes, seconds)
            }
        }
        RunLoop.main.add(recordingTimer!, forMode: .common)
    }

    // MARK: - Flip Camera
    func flipCamera() {
        self.btnFlipCamera.isUserInteractionEnabled = false
        UIView.transition(with: previewView, duration: 0.3, options: .transitionFlipFromLeft, animations: nil) { _ in
            self.btnFlipCamera.isUserInteractionEnabled = true
        }

        let newPosition: AVCaptureDevice.Position = (activeCamera?.position == .back) ? .front : .back
        let newDeviceType: AVCaptureDevice.DeviceType = (newPosition == .back) ? .builtInDualWideCamera : .builtInWideAngleCamera

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [newDeviceType],
            mediaType: .video,
            position: newPosition
        )

        if let newDevice = discoverySession.devices.first {
            activeCamera = newDevice
            configureCameraInput(device: newDevice)
//            print("Flipped to \(newDevice.localizedName)")
//            print("Min zoom: \(newDevice.minAvailableVideoZoomFactor), Max zoom: \(newDevice.maxAvailableVideoZoomFactor)")
        } else {
            print("Dual wide camera not found, falling back to wide")
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) {
                activeCamera = device
                configureCameraInput(device: device)
//                print("Using \(device.localizedName)")
//                print("Min zoom: \(device.minAvailableVideoZoomFactor), Max zoom: \(device.maxAvailableVideoZoomFactor)")
            }
        }

        self.btnUltraWideAngle.superview?.superview?.isHidden = newPosition == .back && (hasUltraWideCamera()) ? false : true
        self.updateZoomButtons(ultraWideActive: false)
        self.resetFlash()
    }

    // MARK: - Flash Toggle
    func toggleFlash() {

        if activeCamera?.position == .front && isPhoto {
            if currentFlashMode == .on {
                currentFlashMode = .off
                btnFlash.tintColor = .white
            } else {
                currentFlashMode = .on
                btnFlash.tintColor = .yellow
            }
            return
        }

        guard let device = activeCamera, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if currentFlashMode == .on {
                currentFlashMode = .off
                btnFlash.tintColor = .white
                device.torchMode = isPhoto ? .off : .off
            } else {
                currentFlashMode = .on
                btnFlash.tintColor = .yellow
                device.torchMode = !isPhoto ? .on : .off
            }
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error.localizedDescription)")
        }
    }
}

// MARK: - Photo Capture Delegate Methods
extension SwiftySnapViewController: @preconcurrency AVCapturePhotoCaptureDelegate {

    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), var image = UIImage(data: imageData) else { return }

        // Save image or pass it to another screen
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // Correct mirroring for front camera
        if activeCamera?.position == .front {
            if let cgImage = image.cgImage {
                // Flip horizontally by creating a mirrored UIImage
                image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
            }
        }

        self.btnShutter.isUserInteractionEnabled = true
        self.dismiss(animated: true) {
            self.delegate?.cameraDidCapturePhoto(image)
        }
    }
}

// MARK: - Video Recording Delegate Methods
extension SwiftySnapViewController: @preconcurrency AVCaptureFileOutputRecordingDelegate {

    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.btnShutter.isUserInteractionEnabled = true
        if error == nil {
            self.dismiss(animated: true) {
                self.delegate?.cameraDidCaptureVideo(url: outputFileURL)
            }
        }
    }
}

//MARK: - Helper Function
func hasUltraWideCamera() -> Bool {
    // Create a discovery session to find all available camera devices
    let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
        mediaType: .video,
        position: .back
    )

    return discoverySession.devices.contains { $0.deviceType == .builtInUltraWideCamera }
}

