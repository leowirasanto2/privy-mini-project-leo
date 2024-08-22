//
//  FaceRecogView.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 22/08/24.
//

import UIKit
import AVFoundation
import Vision

enum ValidationState {
    case faceForward
    case rotateLeft
    case rotateRight
    case success
    case failed
}

class FaceRecogView: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var session: AVCaptureSession? = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var pinchScale: CGFloat = 1
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCaptureOutput?
    private var videoOutput: AVCaptureVideoDataOutput? = AVCaptureVideoDataOutput()
    
    private var state: ValidationState = .rotateRight {
        didSet {
            messageLabel.textColor = .black
            switch state {
            case .faceForward:
                messageLabel.text = "Please face forward"
            case .rotateLeft:
                messageLabel.text = "Please rotate your face to left"
            case .rotateRight:
                messageLabel.text = "Please rotate your face to right"
            case .success:
                messageLabel.textColor = .green
                messageLabel.text = "Face validation success!"
            case .failed:
                messageLabel.text = "Face validation failed!"
            }
        }
    }
    
    private var messageLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .black
        $0.font = .systemFont(ofSize: 24, weight: .semibold)
        $0.textAlignment = .center
        return $0
    }(UILabel())
    
    private var overlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupOverlay()
        runCamera()
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.session?.startRunning()
        }
        
        state = .rotateRight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFrame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session?.stopRunning()
        session = nil
        videoOutput = nil
        photoOutput = nil
    }
    
    private func setupView() {
        view.backgroundColor = .white
    }
    
    private func setupOverlay() {
        view.addSubview(messageLabel)
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
            
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        overlayView.createCircleOverlay(view, 380)
    }
    
    private func forceToFrontCamera() -> AVCaptureDevice? {
        let captureSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        return captureSession.devices.first
    }
    
    private func runCamera() {
        if let device = forceToFrontCamera() {
            captureDevice = device
        }
        if let captureDevice = captureDevice, let session = session {
            session.sessionPreset = AVCaptureSession.Preset.photo
            do {
                try session.addInput(AVCaptureDeviceInput(device: captureDevice))
                
                if let photoOutput = photoOutput, session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                }
            }
            catch {
                print("error: \(error.localizedDescription)")
            }
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer?.frame = UIScreen.main.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            
            if let previewLayer = previewLayer {
                self.view.layer.addSublayer(previewLayer)
                rearrangeOverlayView()
            }
            session.commitConfiguration()
        }
    }
    
    private func rearrangeOverlayView() {
        self.view.bringSubviewToFront(overlayView)
        self.view.bringSubviewToFront(messageLabel)
    }
    
    private func setupFrame() {
        videoOutput?.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoOutput?.alwaysDiscardsLateVideoFrames = true
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        if let videoOutput = videoOutput, let session = session, !session.outputs.contains(videoOutput) {
            session.addOutput(videoOutput)
        }
        guard let connection = videoOutput?.connection(with: .video), connection.isVideoRotationAngleSupported(90) else {
            return
        }
        connection.videoRotationAngle = 90
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate Implementation
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        detectFace(image: frame)
    }
}

// MARK: - setup face detection
private extension FaceRecogView {
    func detectFace(image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { vnRequest, error in
            DispatchQueue.main.async {
                if let results = vnRequest.results as? [VNFaceObservation], results.count > 0 {
                    self.handleFaceDetectionResults(observedFaces: results, pixelBuffer: image)
                }
            }
        }
        
        let imageResultHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageResultHandler.perform([faceDetectionRequest])
    }
    
    func handleFaceDetectionResults(observedFaces: [VNFaceObservation], pixelBuffer: CVPixelBuffer) {
        for faceObservation in observedFaces {
            let faceRotationAngle = CGFloat(truncating: faceObservation.yaw ?? 0)
            let rotationThreshold = CGFloat(45.0).toRadians
            
            switch state {
            case .faceForward:
                if abs(faceRotationAngle) <= rotationThreshold {
                    state = .success
                }
            case .rotateLeft:
                if faceRotationAngle < -rotationThreshold {
                    state = .faceForward
                }
            case .rotateRight:
                if faceRotationAngle > rotationThreshold {
                    state = .rotateLeft
                }
            default:
                break
            }
        }
    }
}

extension CGFloat {
  var toRadians: CGFloat {
    return self * .pi / 180
  }
}
