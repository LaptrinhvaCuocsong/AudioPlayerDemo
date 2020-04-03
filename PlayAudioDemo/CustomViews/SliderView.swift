//
//  SliderView.swift
//  PlayAudioDemo
//
//  Created by Apple on 4/2/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class SliderView: UIView {
    // MARK: - Public properties

    var minimumValue: CGFloat = 0
    var maximumValue: CGFloat = 0

    var currentValue: CGFloat {
        var value = thumbImageView.center.x / bounds.width * maximumValue
        value = value <= maximumValue ? value : maximumValue
        return value
    }

    var beginValueChange: ((CGFloat) -> Void)?
    var valueChange: ((CGFloat, Bool) -> Void)?
    var endValueChange: ((CGFloat) -> Void)?

    var sliderBackground: UIColor? {
        willSet {
            sliderView.backgroundColor = newValue
        }
    }

    var thumbImage: UIImage? {
        willSet {
            thumbImageView.image = newValue
        }
    }

    // MARK: - Private properties

    private var sliderView: UIView!
    private var thumbImageView: UIImageView!
    private var thumbImagePanGesture: UIPanGestureRecognizer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupFrame()
        sliderView.corner(sliderView.frame.height / 2)
        thumbImageView.corner(thumbImageView.frame.height / 2)
    }

    // MARK: - Public method

    func updateSlider(value: CGFloat, animated: Bool = false) {
        let newPosition = value / maximumValue * bounds.width
        let duration = animated ? 0.5 : 0
        UIView.animate(withDuration: duration) {
            self.thumbImageView.center.x = newPosition
        }
        valueChange?(value, animated)
    }

    // MARK: - Private method

    private func setup() {
        sliderView = UIView()
        thumbImageView = UIImageView()
        thumbImageView.contentMode = .scaleAspectFill
        addSubview(sliderView)
        addSubview(thumbImageView)
        setupUserInteraction()
    }

    private func setupFrame() {
        sliderView.frame = bounds
        thumbImageView.frame = CGRect(x: -32, y: 0, width: 64, height: 64)
        thumbImageView.center.y = bounds.height / 2
    }

    private func setupUserInteraction() {
        thumbImageView.isUserInteractionEnabled = true
        thumbImagePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlerPanThumbImageView(sender:)))
        thumbImageView.addGestureRecognizer(thumbImagePanGesture)
    }

    @objc private func handlerPanThumbImageView(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self)
        switch sender.state {
        case .began:
            beginValueChange?(currentValue)
        case .changed:
            if point.x >= 0 && point.x <= bounds.width {
                thumbImageView.center.x = point.x
                valueChange?(currentValue, false)
            }
        case .ended:
            endValueChange?(currentValue)
        default:
            break
        }
    }
}
