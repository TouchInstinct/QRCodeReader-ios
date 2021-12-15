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

open class QRCodeReader: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    private let sessionQueue = DispatchQueue(label: "qr_capture_session_queue")
    private let metadataObjectsQueue = DispatchQueue(label: "qr_metadata_objects_queue", attributes: [], target: nil)
    
    internal weak var readerView: QRCodeReaderView?
    
    lazy var defaultDeviceInput: AVCaptureDeviceInput? = {
        guard let defaultDevice = defaultDevice else {
            return nil
        }

        return try? AVCaptureDeviceInput(device: defaultDevice)
    }()

    // MARK: - Public Properties
    
    let session = AVCaptureSession()

    let metadataOutput = AVCaptureMetadataOutput()
    
    let previewLayer: AVCaptureVideoPreviewLayer

    public let defaultDevice: AVCaptureDevice? = .default(for: .video)

    public var stopScanningWhenCodeIsFound: Bool = true

    public var didFindCode: ((AVMetadataMachineReadableCodeObject) -> Void)?

    public var didFailDecoding: (() -> Void)?

    // MARK: - Public Initializer

    public override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)

        super.init()

        configureDefaultDevice()

        sessionQueue.async {
            self.configureDefaultComponents()
        }
    }
    
    // MARK: - Deinitializer
    
    deinit {
        isTorchEnabled = false
    }
    
    // MARK: - Checking the Reader Availabilities
    
    public class func isAvailable() -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return false
        }
        
        return (try? AVCaptureDeviceInput(device: captureDevice)) != nil
    }

    // MARK: - Controlling Reader

    public func startScanning() {
        readerView?.updateRectOfInterestBasedOnFocusView()
        
        sessionQueue.async {
            guard !self.session.isRunning else {
                return
            }

            self.session.startRunning()
        }
    }

    public func stopScanning() {
        sessionQueue.async {
            guard self.session.isRunning else {
                return
            }

            self.session.stopRunning()
        }
    }

    public var isRunning: Bool {
        return session.isRunning
    }

    public var isTorchAvailable: Bool {
        return defaultDevice?.isTorchAvailable ?? false
    }
    
    public var isTorchEnabled: Bool {
        get {
            return defaultDevice?.torchMode == .on
        }
        set {
            do {
                try defaultDevice?.lockForConfiguration()
                defer {
                    defaultDevice?.unlockForConfiguration()
                }

                let newTorchMode: AVCaptureDevice.TorchMode = newValue ? .on : .off
                let isTorchModeSupported = defaultDevice?.isTorchModeSupported(newTorchMode) ?? false

                guard isTorchAvailable, isTorchModeSupported else {
                    return
                }

                defaultDevice?.torchMode = newTorchMode
            } catch _ { }
        }
        
    }
    
    // MARK: - Private Methods
    
    private func configureDefaultComponents() {
        if let defaultDevice = defaultDevice,
           defaultDevice.supportsSessionPreset(.hd4K3840x2160) {
            session.sessionPreset = .hd4K3840x2160
        }

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
    
    private func configureDefaultDevice() {
        guard let device = defaultDevice else { return }

        do {
            try device.lockForConfiguration()

            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }

            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            if device.isLowLightBoostSupported {
                device.automaticallyEnablesLowLightBoostWhenAvailable = true
            }

            device.unlockForConfiguration()
        } catch _ { }
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
                        self.didFindCode?(readableCodeObject)
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
