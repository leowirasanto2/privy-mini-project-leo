//
//  FaceRecogView.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 22/08/24.
//

import UIKit
import AVFoundation
import Vision

class FaceRecogView: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var session: AVCaptureSession? = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var pinchScale: CGFloat = 1
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCaptureOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var drawings: [CAShapeLayer] = []
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFrame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session?.stopRunning()
        movieOutput?.stopRecording()
        session = nil
        videoOutput = nil
        photoOutput = nil
    }
    
    private func setupView() {
        view.backgroundColor = .white
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
            }
            session.commitConfiguration()
        }
    }
    
    private func setupFrame() {
        videoOutput?.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoOutput?.alwaysDiscardsLateVideoFrames = true
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camframe_queue"))
        if let videoOutput = videoOutput, let session = session, !session.outputs.contains(videoOutput) {
            session.addOutput(videoOutput)
        }
        guard let connection = videoOutput?.connection(with: .video), connection.isVideoRotationAngleSupported(90) else {
            return
        }
        connection.videoRotationAngle = 90
    }
    
    // AVCaptureVideoDataOutputSampleBufferDelegate Implementation
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        detectFace(image: frame)
    }
    
    private func resetDrawings() {
        drawings.forEach { $0.removeFromSuperlayer() }
        drawings.removeAll()
    }
    
    private func detectFace(image: CVPixelBuffer) {
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
    
    private func handleFaceDetectionResults(observedFaces: [VNFaceObservation], pixelBuffer: CVPixelBuffer) {
        
        resetDrawings()
        
        guard let previewLayer = previewLayer else {
            return
        }
        for faceObservation in observedFaces {
            let faceBoundingBoxOnScreen = previewLayer.layerRectConverted(fromMetadataOutputRect: faceObservation.boundingBox)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(faceBoundingBoxShape)
            drawings.append(faceBoundingBoxShape)
        }
    }
}
