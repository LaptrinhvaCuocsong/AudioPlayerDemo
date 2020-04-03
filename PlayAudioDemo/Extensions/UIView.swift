//
//  UIView.swift
//  PlayAudioDemo
//
//  Created by Apple on 4/2/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

extension UIView {
    func corner(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
}
