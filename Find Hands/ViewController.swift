//
//  ViewController.swift
//  Find Hands
//
//  Created by Ishan Sharma on 4/15/18.
//  Copyright © 2018 Ishan Sharma. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // connections for the views
    @IBOutlet weak var classificationText: UILabel!
    @IBOutlet weak var cameraView: UIView!
    
    // the video capture session obejct - this receives camera output from OS
    let cameraViewSession = AVCaptureSession()
    
    // creating a queue to process the video frames
    let frameQueue = DispatchQueue(label: "frameQueue")
    
    // preview layer to display the came input
    var previewDisplayLayer: AVCaptureVideoPreviewLayer!
    
    // vision request
    var visionRequests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard let camera = AVCaptureDevice.default(for: .video) else {
            classificationText.text = "No camera present"
            fatalError("No camera present or available")
        }
        
        cameraViewSession.sessionPreset = .high // may need to adjust this a bit
        
        // show the preview layer in UI
        previewDisplayLayer = AVCaptureVideoPreviewLayer(session: cameraViewSession)
        cameraView.layer.addSublayer(previewDisplayLayer)
        
        // creating capture input and video output
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true // discard late frames. Otherwise, we may have inconsistent frames
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            // connect the output and input
            cameraViewSession.addInput(cameraInput)
            cameraViewSession.addOutput(videoOutput)
            
            // ensure portrait mode
            let conn = videoOutput.connection(with: .video)
            conn?.videoOrientation = .portrait
            
            // initiate session
            cameraViewSession.startRunning()
            
            classificationText.text = "AV Session Initialized. Searching for hands..."
        } catch _ {
            fatalError("Could not capture camera input")
        }
        
        // setup the vision framework requests
        guard let visionModel = try? VNCoreMLModel(for: hands_cnn().model) else {
            fatalError("Error while loading model")
        }
        
        classificationText.text = "Model loaded"
        
        // setup request using custom trained model
        let classifierRequest = VNCoreMLRequest(model: visionModel, completionHandler: processClassifications)
        classifierRequest.imageCropAndScaleOption = .centerCrop
        visionRequests = [classifierRequest]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewDisplayLayer.frame = self.cameraView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption: Any] = [:]
        if let cameraData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: cameraData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    func processClassifications(request: VNRequest, error: Error?) {
        if let theError = error {
            print("Error: \(theError.localizedDescription)")
            return
        }
        
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        let classifications = observations[0...2] // get top 2 results
            .compactMap({ $0 as? VNClassificationObservation })
            .compactMap({ $0.confidence > 0.03 ? $0 : nil })
            .map({ "\($0.identifier) \(String(format: "%.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        DispatchQueue.main.async{
            self.classificationText.text = classifications
        }
    }


}

