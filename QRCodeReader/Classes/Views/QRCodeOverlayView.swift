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

open class QRCodeOverlayView: UIView {

    public weak var focusView: QRCodeFocusView?

    override open func draw(_ rect: CGRect) {

        guard let focusView = focusView else {
            return
        }

        let cutoutShape = convert(focusView.frame, from: focusView)
        let cornerOffset = focusView.cornerThickness
        let cornerRectSideLength = focusView.cornerLength + focusView.cornerThickness

        let cornerSize = CGSize(width: cornerRectSideLength,
                                height: cornerRectSideLength)

        focusView.cornerColor.setFill()

        drawCornerRect(with: cornerSize,
                       xOffset: cutoutShape.minX - cornerOffset,
                       yOffset: cutoutShape.minY - cornerOffset)

        drawCornerRect(with: cornerSize,
                       xOffset: cutoutShape.maxX - cornerRectSideLength + cornerOffset,
                       yOffset: cutoutShape.minY - cornerOffset)

        drawCornerRect(with: cornerSize,
                       xOffset: cutoutShape.minX - cornerOffset,
                       yOffset: cutoutShape.maxY - cornerRectSideLength + cornerOffset)

        drawCornerRect(with: cornerSize,
                       xOffset: cutoutShape.maxX - cornerRectSideLength + cornerOffset,
                       yOffset: cutoutShape.maxY - cornerRectSideLength + cornerOffset)

        UIGraphicsGetCurrentContext()?.clear(cutoutShape)
    }

    // MARK: - Helpers

    private func drawCornerRect(with size: CGSize, xOffset: CGFloat, yOffset: CGFloat) {
        let cornerRect = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: size)
        let cornerPath = UIBezierPath(rect: cornerRect)
        cornerPath.fill()
    }
}
