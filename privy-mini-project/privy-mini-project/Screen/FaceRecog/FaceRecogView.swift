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
    case preparation
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
            onStateChanged()
        }
    }
    
    private var messageLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .black
        $0.textAlignment = .center
        return $0
    }(UILabel())
    
    private var titleLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .red
        $0.font = .systemFont(ofSize: 24, weight: .semibold)
        $0.textAlignment = .center
        return $0
    }(UILabel())
    
    private var instructionView: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView())
    
    private var actionButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .red
        $0.setTitleColor(.white, for: .normal)
        $0.setTitle("Ambil swafoto", for: .normal)
        $0.layer.cornerRadius = 25
        $0.layer.masksToBounds = true
        return $0
    }(UIButton())
    
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
        runCamera()
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.session?.startRunning()
        }
        
        state = .preparation
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
        setupOverlay()
        setupInstructionView()
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
    
    @objc
    private func onActionTapped(_ sender: Any) {
        if state == .preparation {
            state = .rotateRight
        }
        
        if state == .success {
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func rearrangeOverlayView() {
        self.view.bringSubviewToFront(overlayView)
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

// MARK: - setup state & views
private extension FaceRecogView {
    func onStateChanged() {
        messageLabel.textColor = .black
        actionButton.setTitleColor(.black, for: .normal)
        actionButton.setTitle("Mohon ikuti instruksi", for: .normal)
        actionButton.isEnabled = state == .preparation || state == .success
        actionButton.backgroundColor = .gray.withAlphaComponent(0.5)
        switch state {
        case .preparation:
            messageLabel.text = ""
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.setTitle("Ambil swafoto", for: .normal)
            actionButton.backgroundColor = .red
        case .faceForward:
            messageLabel.text = "Please face forward"
        case .rotateLeft:
            messageLabel.text = "Please rotate your face to left"
        case .rotateRight:
            messageLabel.text = "Please rotate your face to right"
        case .success:
            messageLabel.textColor = .green
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.setTitle("Selesai", for: .normal)
            actionButton.backgroundColor = .red
            messageLabel.text = "Face validation success!"
        case .failed:
            messageLabel.text = "Face validation failed!"
        }
    }
    
    func setupInstructionView() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fill
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = 16
        instructionView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: instructionView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: instructionView.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: instructionView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: instructionView.bottomAnchor, constant: -16),
        ])
        
        let image = UIImageView(image: UIImage(systemName: "person.circle"))
        image.translatesAutoresizingMaskIntoConstraints = false
        image.heightAnchor.constraint(equalToConstant: 45).isActive = true
        image.widthAnchor.constraint(equalToConstant: 45).isActive = true
        image.tintColor = .red
        let label = UILabel()
        label.textColor = .black
        label.text = "Sesuaikan wajah dengan garis panduan"
        label.numberOfLines = 2
        [image, label].forEach {
            stack.addArrangedSubview($0)
        }
    }
    
    func setupOverlay() {
        view.addSubview(overlayView)
        overlayView.addSubview(instructionView)
        overlayView.addSubview(messageLabel)
        overlayView.addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -16),
            
            messageLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: 180),
            
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            instructionView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            instructionView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
            instructionView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: 16),
            
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            actionButton.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -16),
            actionButton.topAnchor.constraint(equalTo: instructionView.bottomAnchor, constant: 16),
        ])
        overlayView.createCircleOverlay(view, 280)
        
        actionButton.addTarget(self, action: #selector(onActionTapped), for: .touchUpInside)
    }
}

extension CGFloat {
  var toRadians: CGFloat {
    return self * .pi / 180
  }
}
