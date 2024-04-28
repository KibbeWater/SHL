//
//  PromotionBanner.swift
//  LHF Demo
//
//  Created by user242911 on 3/25/24.
//

import SwiftUI

struct PromotionBanner: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button {
            openURL(URL(string: "https://apps.apple.com/se/app/shl-matchtracker/id6479990812")!)
        } label: {
            Text("This experience is limited, click here to install the full app from the App Store")
                .fontWeight(.semibold)
                .padding(.horizontal)
        }
        .buttonStyle(.borderedProminent)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PromotionBanner()
}
