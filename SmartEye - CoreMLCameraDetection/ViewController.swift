//
//  ViewController.swift
//  SmartCameraProjectTest
//
//  Created by Joseph Bouhanef on 2020-05-04.
//  Copyright © 2020 Joseph Bouhanef. All rights reserved.
//

import UIKit
import AVKit
import Vision


class ViewController: UIViewController, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    let identifierLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name:"Avenir Next", size: 20.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.font = label.font.withSize(30)
        return label
    }()
    
    let confidenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name: "Avenir Next", size: 20.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // starting up the camera
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard  let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        setPreviewLayer(captureSession)
        
        setImageOutput(captureSession)
        
        setupidentifierLabel()
        setupConfidenceLabel()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("Camera was able to capture the frame at:", Date())
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return}
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            //perhaps chek the error
            //print(finishedReq.results)
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObseervation = results.first else { return }
            
            DispatchQueue.main.async {
                self.identifierLabel.text = "Object: \(firstObseervation.identifier)"
                self.confidenceLabel.text = "Confidence: \(String(format: "%.2f",firstObseervation.confidence * 100))%"
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

fileprivate extension ViewController {
    
    func setupConfidenceLabel() {
        view.addSubview(confidenceLabel)
        confidenceLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -75).isActive = true
        confidenceLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        confidenceLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        confidenceLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupidentifierLabel() {
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -85).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    func setImageOutput(_ captureSession: AVCaptureSession) {
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    
    func setPreviewLayer(_ captureSession: AVCaptureSession) {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }
}
