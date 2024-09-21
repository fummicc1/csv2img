//
//  UIApplication+Ex.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/14.
//

import Foundation

#if os(iOS)
    import UIKit
    extension Application {
        var activeRootViewController: UIViewController? {
            self.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .compactMap { $0.keyWindow }.first?
                .rootViewController
        }
    }
#endif
