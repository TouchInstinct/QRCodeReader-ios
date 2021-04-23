//
//  Copyright (c) 2019 Touch Instinct
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the Software), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import AVFoundation
import Vision

@available(iOS 13, *)
open class CardReader: BaseReader<Card> {
    
    private let scannerObjectsQueue = DispatchQueue(label: "scanner_objects_queue", attributes: [], target: nil)
    private let factory: CardFactory
    
    private var request: VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        return request
    }
    
    private let videoDataOutput = AVCaptureVideoDataOutput()

    init(factory: CardFactory, onUpdateRectOfInterest: (() -> Void)?) {
        self.factory = factory
        
        super.init(onUpdateRectOfInterest: onUpdateRectOfInterest)
    }
    
    // MARK: - Private Methods
    
    override func configureDefaultComponents() {
        
        session.beginConfiguration()
        
        for output in session.outputs {
            session.removeOutput(output)
        }
        for input in session.inputs {
            session.removeInput(input)
        }
        
        if let defaultDeviceInput = defaultDeviceInput {
            session.addInput(defaultDeviceInput)
        }
        
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: scannerObjectsQueue)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        session.addOutput(videoDataOutput)
    
        previewLayer.videoGravity = .resizeAspectFill
        
        session.commitConfiguration()
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {

        guard let results = request.results as? [VNRecognizedTextObservation] else {
            DispatchQueue.main.async {
                self.didFailDecoding?()
            }
            
            return
        }
        
        let maximumCandidates = 1
        
        let lines = results.flatMap { $0.topCandidates(maximumCandidates).map { $0.string } }
        
        guard let card = factory.create(lines) else {
            return
        }
        
        guard self.session.isRunning else {
            return
        }

        if self.stopScanningWhenCodeIsFound {
            self.session.stopRunning()
        }

        DispatchQueue.main.async {
            self.didFind?(card)
        }
    }
}

@available(iOS 13, *)
extension CardReader: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: .right, options: [:])
        
        sessionQueue.async { [weak self] in
            guard let request = self?.request else {
                return
            }
            
            try? requestHandler.perform([request])
        }
    }
}
