//
//  QRScannerView.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 22/08/24.
//

import UIKit
import AVFoundation
import Security

class QRScannerView: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureSession: AVCaptureSession?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            startSession()
        }
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    private func setupView() {
        view.backgroundColor = .white
        scanner()
    }
    
    private func scanner() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession?.canAddInput(videoInput) == true {
                captureSession?.addInput(videoInput)
            } else {
                failed()
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession?.canAddOutput(metadataOutput) == true {
                captureSession?.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                failed()
                return
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            startSession()
        } catch {
            failed()
            return
        }
    }
    
    func failed() {
        let alertController = UIAlertController(title: "Not supported", message: "Your device does not support QR code scanning.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession?.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            //TODO: - We need to
            // STEP 1: Decrypt the `stringValue` using providedPublic key
            // STEP 2: the result is a Base64 value
            // STEP 3: decode it and we will get user_image, username, privy_id
            // STEP 4: render to custom dialog view
            
            decryptResult(stringValue)
        } else {
            startSession()
        }
    }
    
    func decryptResult(_ result: String) {
        guard let encryptedData = Data(base64Encoded: result, options: [.ignoreUnknownCharacters]) else {
            return
        }
        
        let publicKeyData = Data(base64Encoded: QRKey.publicKey)
        
        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(publicKeyData! as CFData, [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 2048
        ] as NSDictionary, &error) else {
            return
        }
        guard let decryptedData = SecKeyCreateDecryptedData(publicKey, .rsaEncryptionPKCS1, encryptedData as CFData, &error) as Data? else {
            return
        }
        
        let base64DecryptedString = decryptedData.base64EncodedString()
        print("Base64 Encoded Decrypted Data: \(base64DecryptedString)")

        guard let base64DecodedData = Data(base64Encoded: base64DecryptedString, options: [.ignoreUnknownCharacters]) else {
            print("Failed to decode Base64 string.")
            return
        }
        
        do {
            // Convert decrypted data to JSON object
            if let jsonObject = try JSONSerialization.jsonObject(with: base64DecodedData, options: []) as? [String: Any] {
                print("JSON Object: \(jsonObject)")
                // Access JSON fields
                if let userImage = jsonObject["user_image"] as? String,
                   let username = jsonObject["username"] as? String,
                   let privyId = jsonObject["privy_id"] as? String {
                    print("User Image URL: \(userImage)")
                    print("Username: \(username)")
                    print("Privy ID: \(privyId)")
                }
            } else {
                print("Decrypted data is not valid JSON.")
            }
        } catch {
            print("Failed to convert data to JSON: \(error.localizedDescription)")
        }
    }

}
