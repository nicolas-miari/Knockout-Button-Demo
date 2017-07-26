//
//  KnockoutButton.swift
//  KnockoutButtonDemo
//
//  Created by Nicolás Miari on 2017/04/25.
//  Copyright © 2017 Nicolás Miari. All rights reserved.
//

import UIKit

/// Custom button control that renders its contents as "knock out" (cut out) 
/// from a solid background.
/// The base class has no subviews (contents) by default. Subviews should be 
/// added through the array property `contents`, and will be stacked 
/// horizontally left to right, vertically centered, separated by from each 
/// other and the button's bounds by `margin`.
///
/// - note: Refactor the left-to-right horizontal layout capabilities into an
/// intermediate subclass, and keep only the knock-out functionality.
///
@IBDesignable
class KnockoutButton: UIControl {

    /// Minimum padding between button's bounds and its subviews.
    ///
    @IBInspectable var margin: CGFloat = 5.0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    /// Background (fill) color used to draw the **normal** state.
    ///
    @IBInspectable var normalFillColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Background (fill) color used to draw the **highlighted** state.
    ///
    @IBInspectable var highlightedFillColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Curvature radius of the rounded corners.
    ///
    @IBInspectable var cornerRadius: CGFloat {
        set (newValue) {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    /// Specifies the (ordered) subview components to knock out of the button.
    /// Components are laid out stacked horizontally from left to right, at 
    /// `margin` distance from each other and the button's left and right 
    /// borders.
    ///
    /// - important: Do not use `addSubview()`: views added that way will not be
    ///   knocked out, and will be removed when setting this property.
    /// - note: Setting this property removes all existing subviews of the 
    ///   button.
    ///
    var contents: [UIView] {
        didSet {
            self.subviews.forEach({ subview in
                subview.removeFromSuperview()
            })

            contents.forEach({subview in
                if let imageView = subview as? UIImageView {
                    // Make image tinted white
                    let tintedImage = imageView.image?.tinted(color: UIColor.white)
                    imageView.image = tintedImage

                } else if let label = subview as? UILabel {
                    // Make text white
                    label.textColor = UIColor.white
                }

                self.addSubview(subview)
            })
            setNeedsUpdateConstraints()
        }
    }

    // MARK: - UIView

    override var intrinsicContentSize: CGSize {
        var size = CGSize(width: margin, height: 0)

        subviews.forEach({ subview in
            subview.sizeToFit()
            let frame = subview.frame

            size.height = max(size.height, frame.height + 2*margin)
            size.width += frame.width + margin
        })

        return size
    }

    // MARK: - UIControl

    override var isHighlighted: Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        contents = []
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        contents = []
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        self.isOpaque = false
        self.tintColor = UIColor.white
        self.backgroundColor = UIColor.clear
    }

    // MARK: - UIView

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return super.draw(rect) // Shouldn't happen.
        }

        context.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: rect.height))
        // (CGGraphicsCntext uses upside-down coordinate system)

        // First, unhide subviews and render view to a bitmap:

        subviews.forEach({ subview in
            subview.isHidden = false

            subview.setNeedsDisplay()
            // ^ If absent, labels don't render the first time.
            // Investigate if there isn't a better design to prevent the
            // phenomenon.
        })

        defer {
            // Before returning, re-hide all subviews (whether drawing was 
            // successful or not):
            subviews.forEach({ subview in
                subview.isHidden = true
            })
        }

        // This prevents a bug where the label isn't rendered the first time:
        //label.setNeedsDisplay()

        guard let image = self.render()?.cgImage else {
            return // Shouldn't happen.
        }

        // Create a mask from the normally rendered image:
        guard let mask = CGImage(
            maskWidth: image.width,
            height: image.height,
            bitsPerComponent: image.bitsPerComponent,
            bitsPerPixel: image.bitsPerPixel,
            bytesPerRow: image.bytesPerRow,
            provider: image.dataProvider!,
            decode: image.decode,
            shouldInterpolate: image.shouldInterpolate) else {
                return
        }

        // Wipe the slate clean:
        context.clear(rect)

        context.saveGState()

        // Apply mask and fill with backround color:
        context.clip(to: rect, mask: mask)

        if isHighlighted {
            highlightedFillColor?.set()
        } else {
            normalFillColor?.set()
        }
        context.fill(rect)

        context.restoreGState()
    }

    override func updateConstraints() {
        super.updateConstraints()

        for (index, subview) in subviews.enumerated() {

            subview.sizeToFit()

            if index == 0 {
                // First
                subview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: margin).isActive = true
            } else {
                // Non-first
                subview.leftAnchor.constraint(
                    equalTo: subviews[index - 1].rightAnchor,
                    constant: margin
                ).isActive = true
            }

            // Common
            subview.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

            if index == subviews.count - 1 {
                // Last
                subview.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -margin).isActive = true
            }
        }

        setNeedsDisplay()
    }
}

// MARK: - Support

extension UIView {
    func render() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        self.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImage {
    func tinted(color: UIColor) -> UIImage? {
        let image = self
        let rect: CGRect = CGRect(origin: CGPoint(x: 0, y: 0), size: image.size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()!
        image.draw(in: rect)
        context.setFillColor(color.cgColor)
        context.setBlendMode(.sourceAtop)
        context.fill(rect)
        if let result: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return result
        } else {
            return nil
        }
    }
}
