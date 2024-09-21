//
//  Type.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/22.
//

import Foundation
import SwiftUI

#if os(macOS)
    import AppKit
    typealias Application = NSApplication
    typealias ApplicationDelegate = NSApplicationDelegate
    typealias ApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
    typealias Responder = NSResponder
    typealias ViewRepresentable = NSViewRepresentable
#elseif os(iOS)
    import UIKit
    typealias Application = UIApplication
    typealias ApplicationDelegate = UIApplicationDelegate
    typealias ApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
    typealias Responder = UIResponder
    typealias ViewRepresentable = UIViewRepresentable
#endif
