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

open class FocusView: UIView {

    public var cornerColor: UIColor {
        didSet {
            if cornerColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var cornerLength: CGFloat {
        didSet {
            if cornerLength != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var cornerThickness: CGFloat {
        didSet {
            if cornerThickness != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: - Public Initializers

    public init(cornerColor: UIColor,
                cornerLength: CGFloat,
                cornerThickness: CGFloat) {
        
        self.cornerColor = cornerColor
        self.cornerLength = cornerLength
        self.cornerThickness = cornerThickness

        super.init(frame: .zero)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    override open func setNeedsDisplay() {
        super.setNeedsDisplay()
        
        // Go up into view hierarchy, find QRCodeOverlayView and redraw it
        var currentSuperview = superview
        
        while let view = currentSuperview {
            if view is OverlayView {
                view.setNeedsDisplay()
                return
            } else {
                currentSuperview = view.superview
            }
        }
    }
}
