//
//  VersusBar.swift
//  SHL
//
//  Created by user242911 on 4/1/24.
//

import SwiftUI

struct VersusBar: View {
    var title: String
    var homeSide: Float
    var awaySide: Float

    var homeColor: Color
    var awayColor: Color

    private var isPercent: Bool

    init(_ title: String, homeSide: Int, awaySide: Int, homeColor: Color, awayColor: Color) {
        self.title = title
        self.homeSide = Float(homeSide)
        self.awaySide = Float(awaySide)
        self.homeColor = homeColor
        self.awayColor = awayColor
        self.isPercent = false
    }

    init(_ title: String, homePercent: Float, awayPercent: Float, homeColor: Color, awayColor: Color) {
        self.title = title
        self.homeSide = homePercent
        self.awaySide = awayPercent
        self.homeColor = homeColor
        self.awayColor = awayColor
        self.isPercent = true
    }

    private var homeText: String {
        isPercent ? "\(floor(homeSide * 1000) / 10)%" : String(format: "%.0f", homeSide)
    }

    private var awayText: String {
        isPercent ? "\(floor(awaySide * 1000) / 10)%" : String(format: "%.0f", awaySide)
    }

    private var fraction: CGFloat {
        let total = CGFloat(homeSide + awaySide)
        guard total > 0 else { return 0.5 }
        return CGFloat(homeSide) / total
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(homeText)
                    .font(.title2.weight(.bold))
                    .fontWidth(.compressed)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(homeSide)))
                Spacer()
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Spacer()
                Text(awayText)
                    .font(.title2.weight(.bold))
                    .fontWidth(.compressed)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(awaySide)))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(.quaternary)

                    // Filled portion(s)
                    if homeSide + awaySide == 0 {
                        EmptyView()
                    } else {
                        HStack(spacing: 2) {
                            Capsule()
                                .fill(homeColor)
                                .frame(width: max(0, (geo.size.width - 2) * fraction))
                            Capsule()
                                .fill(awayColor)
                                .frame(width: max(0, (geo.size.width - 2) * (1 - fraction)))
                        }
                    }
                }
            }
            .frame(height: 8)
            .animation(.smooth(duration: 0.5), value: homeSide)
            .animation(.smooth(duration: 0.5), value: awaySide)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        VersusBar("Penalties", homeSide: 3, awaySide: 7, homeColor: .red, awayColor: .blue)
        VersusBar("Shots on goal", homeSide: 37, awaySide: 24, homeColor: .red, awayColor: .blue)
        VersusBar("Save %", homePercent: 0.92, awayPercent: 0.88, homeColor: .red, awayColor: .blue)
        VersusBar("Faceoffs", homeSide: 28, awaySide: 22, homeColor: .red, awayColor: .blue)
        VersusBar("Penalties", homeSide: 0, awaySide: 0, homeColor: .red, awayColor: .blue)
    }
    .padding()
}

#Preview("Dark") {
    VStack(spacing: 16) {
        VersusBar("Penalties", homeSide: 3, awaySide: 7, homeColor: .red, awayColor: .blue)
        VersusBar("Shots on goal", homeSide: 37, awaySide: 24, homeColor: .red, awayColor: .blue)
        VersusBar("Save %", homePercent: 0.92, awayPercent: 0.88, homeColor: .red, awayColor: .blue)
    }
    .padding()
    .preferredColorScheme(.dark)
}
