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

open class BaseReader<Result>: NSObject {

    // MARK: - Public Properties
    
    public let defaultDevice: AVCaptureDevice? = .default(for: .video)
    
    public var stopScanningWhenCodeIsFound: Bool = false
    
    public var didFind: ((Result) -> Void)?
    public var didFailDecoding: (() -> Void)?
    
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
    
    // MARK: - Checking the Reader Availabilities
    
    public class func isAvailable() -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return false
        }
        
        return (try? AVCaptureDeviceInput(device: captureDevice)) != nil
    }
    
    // MARK: - Internal Properties
    
    let session = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer
    let sessionQueue = DispatchQueue(label: "session_queue")
    
    lazy var defaultDeviceInput: AVCaptureDeviceInput? = {
        guard let defaultDevice = defaultDevice else {
            return nil
        }
        
        return try? AVCaptureDeviceInput(device: defaultDevice)
    }()
    
    var onUpdateRectOfInterest: (() -> Void)?
    
    // MARK: - Public Initializer

    public init(onUpdateRectOfInterest: (() -> Void)?) {
        self.onUpdateRectOfInterest = onUpdateRectOfInterest

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        super.init()
        
        sessionQueue.async {
            self.configureDefaultComponents()
        }
    }
    
    // MARK: - Deinitializer
    
    deinit {
        isTorchEnabled = false
    }
    
    // MARK: - Controlling Reader
    public func startScanning() {
        onUpdateRectOfInterest?()
        
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

    // MARK: - Private Methods
    
    func configureDefaultComponents() {
        // override
    }
}
