//
//  SVGImageView.swift
//  LHF
//
//  Created by KibbeWater on 1/4/24.
//

import SwiftUI
import SVGKit

struct SVGImageView: UIViewRepresentable {
    var url:URL
    var size:CGSize
    
    func updateUIView(_ uiView: SVGKFastImageView, context: Context) {
        uiView.contentMode = .scaleAspectFit
        uiView.image.size = size
    }
    
    func makeUIView(context: Context) -> SVGKFastImageView {
        let svgImage = SVGKImage(contentsOf: url)
        return SVGKFastImageView(svgkImage: svgImage ?? SVGKImage())
    }
}

#Preview {
    SVGImageView(url: URL(string: "https://sportality.cdn.s8y.se/team-logos/modo1_modo.svg")!, size: CGSize(width: 64, height: 64))
        .frame(width: 64, height: 64)
}
