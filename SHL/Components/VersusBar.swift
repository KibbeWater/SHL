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
    
    var body: some View {
        VStack {
            HStack {
                Text("\(isPercent ? String("\(floor(homeSide * 1000) / 10)%") : String(format: "%.0f", homeSide))")
                    .font(.title2)
                    .fontWidth(.compressed)
                    .fontWeight(.bold)
                    .padding(2)
                Spacer()
                Text("\(isPercent ? String("\(floor(awaySide * 1000) / 10)%") : String(format: "%.0f", awaySide))")
                    .font(.title2)
                    .fontWidth(.compressed)
                    .fontWeight(.bold)
                    .padding(2)
            }
            .overlay(alignment: .bottom) {
                Text(title)
            }
            GeometryReader { geo in
                let geoW = geo.size.width - 4
                if homeSide+awaySide == 0 {
                    Color.secondary
                        .frame(width: geo.size.width, height: 8)
                } else if homeSide == 0 {
                    awayColor
                        .frame(width: geo.size.width, height: 8)
                } else if awaySide == 0 {
                    homeColor
                        .frame(width: geo.size.width, height: 8)
                } else {
                    HStack(spacing: 0) {
                        HStack{}
                            .frame(width: (CGFloat(homeSide) / CGFloat(homeSide+awaySide)) * geoW, height: 8)
                            .background(homeColor)
                            .clipShape(RoundedRectangle(cornerRadius: .infinity))
                        Spacer()
                        HStack{}
                            .frame(width: (CGFloat(awaySide) / CGFloat(homeSide+awaySide)) * geoW, height: 8)
                            .background(awayColor)
                            .clipShape(RoundedRectangle(cornerRadius: .infinity))
                    }
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    VStack {
        VersusBar("Penalties", homeSide: 3, awaySide: 7, homeColor: .red, awayColor: .blue)
        VersusBar("Shots on goal", homeSide: 37, awaySide: 24, homeColor: .red, awayColor: .blue)
            .padding(.bottom, 64)
        
        VersusBar("Penalties %", homePercent: 0.3, awayPercent: 0.7, homeColor: .red, awayColor: .blue)
        VersusBar("Shots %", homePercent: 0.60655, awayPercent: 0.39344, homeColor: .red, awayColor: .blue)
    }
    .padding(.horizontal)
}
