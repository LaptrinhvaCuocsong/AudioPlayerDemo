//
//  TimeInterval.swift
//  PlayAudioDemo
//
//  Created by Apple on 4/2/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

extension TimeInterval {
    var minute: Double {
        return self / 60
    }

    var time: (minute: Int, seconds: Int) {
        let minute = Int(self / 60)
        let seconds = Int(self - Double(minute) * 60)
        return (minute: minute, seconds: seconds)
    }
}
