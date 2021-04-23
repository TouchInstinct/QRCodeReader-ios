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

open class QRCodeReader: BaseReader<AVMetadataMachineReadableCodeObject>, AVCaptureMetadataOutputObjectsDelegate {

    private let metadataObjectsQueue = DispatchQueue(label: "qr_metadata_objects_queue", attributes: [], target: nil)

    let metadataOutput = AVCaptureMetadataOutput()
    
    // MARK: - Private Methods
    
    override func configureDefaultComponents() {

        for output in session.outputs {
            session.removeOutput(output)
        }
        for input in session.inputs {
            session.removeInput(input)
        }
        
        if let defaultDeviceInput = defaultDeviceInput {
            session.addInput(defaultDeviceInput)
        }
        
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
        metadataOutput.metadataObjectTypes = [.qr, .aztec, .dataMatrix]
        previewLayer.videoGravity = .resizeAspectFill
        
        session.commitConfiguration()
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {

        sessionQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            for current in metadataObjects {
                if let readableCodeObject = current as? AVMetadataMachineReadableCodeObject,
                       readableCodeObject.stringValue != nil {
                    
                    guard self.session.isRunning else {
                        return
                    }

                    if self.stopScanningWhenCodeIsFound {
                        self.session.stopRunning()
                    }

                    DispatchQueue.main.async {
                        self.didFind?(readableCodeObject)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.didFailDecoding?()
                    }
                }
            }
        }
    }
}
