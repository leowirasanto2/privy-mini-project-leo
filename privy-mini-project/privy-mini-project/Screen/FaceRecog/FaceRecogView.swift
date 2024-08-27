//
//  FaceRecogView.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 22/08/24.
//

import UIKit
import AVFoundation
import Vision
import SwiftUI

protocol FaceRecogViewProtocol: AnyObject {
    func onValidationStateChanged(_ newState: ValidationState)
    var navigationController: UINavigationController? { get }
}

enum ValidationState {
    case preparation
    case faceForward
    case rotateLeft
    case rotateRight
    case success
    case failed
}

class FaceRecogView: UIViewController, FaceRecogViewProtocol, AVCaptureVideoDataOutputSampleBufferDelegate {
    var presenter: FaceRecogPresenterProtocol?
    
    private let horizontalSpacing: CGFloat = 80
    private var pinchScale: CGFloat = 1
    private var session: AVCaptureSession? = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCaptureOutput?
    private var videoOutput: AVCaptureVideoDataOutput? = AVCaptureVideoDataOutput()
    
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
        $0.textAlignment = .left
        $0.text = "Verifikasi Wajah"
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
    
    private var overlayView: FaceRecogOverlayView?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        session = nil
        captureDevice = nil
        previewLayer = nil
        photoOutput = nil
        videoOutput = nil
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
        
        presenter?.setState(new: .preparation)
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
        } else {
            let dummyPreview = UIView(frame: UIScreen.main.bounds)
            dummyPreview.layer.backgroundColor = UIColor.brown.cgColor
            
            self.view.layer.addSublayer(dummyPreview.layer)
            rearrangeOverlayView()
        }
    }
    
    @objc
    private func onActionTapped(_ sender: Any) {
        presenter?.performActionButtonTapped()
    }
    
    private func rearrangeOverlayView() {
        guard let overlayView2 = overlayView else { return }
        self.view.bringSubviewToFront(overlayView2)
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
    
    // MARK: - Protocol Implementations
    
    func onValidationStateChanged(_ newState: ValidationState) {
        guard let overlayView = overlayView else { return }
        overlayView.actionButton.setTitleColor(.black, for: .normal)
        overlayView.actionButton.setTitle("Mohon ikuti instruksi", for: .normal)
        overlayView.actionButton.isEnabled = presenter?.isActionButtonEnabled ?? false
        overlayView.actionButton.backgroundColor = .gray.withAlphaComponent(0.5)
        switch newState {
        case .preparation:
            overlayView.stepLabel.text = "Bersiap verifikasi wajah"
            overlayView.actionButton.setTitleColor(.white, for: .normal)
            overlayView.actionButton.setTitle("Ambil swafoto", for: .normal)
            overlayView.actionButton.backgroundColor = .red
        case .faceForward:
            overlayView.stepLabel.text = "Please face forward"
        case .rotateLeft:
            overlayView.stepLabel.text = "Please rotate your face to left"
        case .rotateRight:
            overlayView.stepLabel.text = "Please rotate your face to right"
        case .success:
            overlayView.actionButton.setTitleColor(.white, for: .normal)
            overlayView.actionButton.setTitle("Selesai", for: .normal)
            overlayView.actionButton.backgroundColor = .red
            overlayView.stepLabel.text = "Face validation success!"
        case .failed:
            overlayView.stepLabel.text = "Face validation failed!"
        }
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
            presenter?.handleFaceDetectionResult(faceRotationAngle: faceRotationAngle, rotationThreshold: rotationThreshold)
        }
    }
}

// MARK: - setup state & views
private extension FaceRecogView {
    func setupOverlay() {
        overlayView = FaceRecogOverlayView(view.frame)
        guard let overlayView = overlayView else { return }
        view.addSubview(overlayView)
        overlayView.actionButton.addTarget(self, action: #selector(onActionTapped), for: .touchUpInside)
    }
}

extension CGFloat {
  var toRadians: CGFloat {
    return self * .pi / 180
  }
}


// MARK: - Preview

struct FaceRecogView_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerPreview {
            FaceRecogView()
        }
    }
}
