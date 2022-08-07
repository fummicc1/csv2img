//
//  Binding+Ex.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Foundation
import SwiftUI

extension Binding {
    func isNotNil<V>() -> Binding<Bool> where Value == Optional<V> {
        Binding<Bool> {
            self.wrappedValue != nil
        } set: { v, _ in
            if !v {
                self.wrappedValue = nil
            }
        }
    }

    func isNil<V>() -> Binding<Bool> where Value == Optional<V> {
        Binding<Bool> {
            self.wrappedValue == nil
        } set: { v, _ in
            if v {
                self.wrappedValue = nil
            }
        }
    }
}
