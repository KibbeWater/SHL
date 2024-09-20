//
//  View+Pulse.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 22/8/24.
//

import Foundation
import SwiftUI

@available(iOS 17.0, *)
extension View {
    func pulseShader(time: Double, center: CGPoint, speed: Float = 1200, amplitude: Float = 12.0, decay: Float = 8.0) -> some View {
        modifier(PulseShader(center: center, time: Float(time), speed: speed, amplitude: amplitude, decay: decay))
    }
}

@available(iOS 17.0, *)
struct PulseShader: ViewModifier {
    var center: CGPoint
    var time: Float
    var speed: Float
    var amplitude: Float
    var decay: Float
    
    func body(content: Content) -> some View {
        content
            .colorEffect(ShaderLibrary.pulse(.float2(center), .float(time), .float(speed), .float(amplitude), .float(decay)))
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        VStack {
            Spacer()
            VStack {
                
            }
            .frame(width: 200, height: 200)
            .background(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            AsyncImage(url: .init(string: "https://image-cdn-ak.spotifycdn.com/image/ab67706c0000da84cc83ea9f56fe6130ce96a405")!)
                .frame(width: 200, height: 200)
                .background(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .pulseShader(time: 0, center: CGPoint(x: 100, y: 100))
            Spacer()
        }
    } else {
        VStack {
            
        }
    }
}
