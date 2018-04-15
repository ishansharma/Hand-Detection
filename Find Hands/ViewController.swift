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
        } catch _ {
            fatalError("Could not capture camera input")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewDisplayLayer.frame = self.cameraView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

