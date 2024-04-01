//
//  VersusBar.swift
//  SHL
//
//  Created by user242911 on 4/1/24.
//

import SwiftUI

struct VersusBar: View {
    var title: String
    var homeSide: Int
    var awaySide: Int
    
    var homeColor: Color
    var awayColor: Color
    
    init(_ title: String, homeSide: Int, awaySide: Int, homeColor: Color, awayColor: Color) {
        self.title = title
        self.homeSide = homeSide
        self.awaySide = awaySide
        
        self.homeColor = homeColor
        self.awayColor = awayColor
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("\(homeSide)")
                    .font(.title2)
                    .fontWidth(.compressed)
                    .fontWeight(.bold)
                    .padding(2)
                Spacer()
                Text("\(awaySide)")
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
    }
    .padding(.horizontal)
}
