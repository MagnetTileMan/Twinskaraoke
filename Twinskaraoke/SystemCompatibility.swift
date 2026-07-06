//
//  SystemCompatibility.swift
//  Twinskaraoke
//
//  Created by Sebastian Reid on 6/7/2026.
//


import UIKit

enum SystemCompatibility {
    static var isIOS27OrNewer: Bool {
        if #available(iOS 27.0, *) {
            return true
        }
        // Fallback or double check via process info if beta string parsing is needed
        return ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27
    }
}