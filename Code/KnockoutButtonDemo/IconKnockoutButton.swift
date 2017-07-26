//
//  IconKnockoutButton.swift
//  KnockoutButtonDemo
//
//  Created by Nicolás Miari on 2017/04/26.
//  Copyright © 2017 Nicolás Miari. All rights reserved.
//

import UIKit

/// Custom `KnockoutButton` subclass with one label and two icon images, 
/// supporting the two following layout configurations:
/// 
/// - `labelLeft`: The label is placed to the left, and the two images /
///    immediately to its right.
/// - `labelCenter`: The label is placed between both images.
///
class IconKnockoutButton: KnockoutButton {

    /// Layout configuration constants
    enum Layout {

        /// Used on iPhone.
        ///
        /// `H: |-(margin)-LABEL-(margin)-IMAGE_VIEW_1-(margin)-IMAGE_VIEW_2-(margin)-|`
        case labelLeft

        /// Used on iPad.
        ///
        /// `H: |-(margin)-IMAGE_VIEW_1-(margin)-LABEL-(margin)-IMAGE_VIEW_2-(margin)-|`
        case labelCenter
    }

    /// Layout configuration
    var layout: Layout = .labelLeft

    /// Text label
    private var label: UILabel

    /// Icon image view
    private var imageView: UIImageView

    /// Second icon image view
    private var secondImageView: UIImageView

    /// Label text
    @IBInspectable var title: String? {
        set (newValue) {
            label.text = newValue
            setNeedsUpdateConstraints()
        }
        get {
            return label.text
        }
    }

    @IBInspectable var isTablet: Bool = false {
        didSet {
            self.layout = isTablet ? .labelCenter : .labelLeft
            setup()
        }
    }

    ///
    @IBInspectable var firstImage: UIImage? {
        set (newValue) {
            imageView.image = newValue?.withRenderingMode(.alwaysTemplate)
            setNeedsUpdateConstraints()
        }
        get {
            return imageView.image
        }
    }

    ///
    @IBInspectable var secondImage: UIImage? {
        set (newValue) {
            secondImageView.image = newValue?.withRenderingMode(.alwaysTemplate)
            setNeedsUpdateConstraints()
        }
        get {
            return secondImageView.image
        }
    }

    ///
    @IBInspectable var fontSize: CGFloat = 18.0 {
        didSet {
            label.font = UIFont.boldSystemFont(ofSize: fontSize)
            setNeedsUpdateConstraints()
        }
    }

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        label = UILabel(frame: CGRect.zero)
        imageView = UIImageView(frame: CGRect.zero)
        secondImageView = UIImageView(frame: CGRect.zero)
        super.init(coder: aDecoder)

        setup()
    }

    override init(frame: CGRect) {
        label = UILabel(frame: CGRect.zero)
        imageView = UIImageView(frame: CGRect.zero)
        secondImageView = UIImageView(frame: CGRect.zero)
        super.init(frame: frame)

        setup()
    }

    /// Setup common to both initialization paths (storyboard and programmatical)
    private func setup() {
        label.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        secondImageView.translatesAutoresizingMaskIntoConstraints = false

        label.font = UIFont.boldSystemFont(ofSize: fontSize)

        switch layout {
        case .labelLeft:
            self.contents = [label, imageView, secondImageView]

        case .labelCenter:
            self.contents = [imageView, label, secondImageView]
        }
    }
}
