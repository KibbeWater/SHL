//
//  PromotionBanner.swift
//  LHF Demo
//
//  Created by user242911 on 3/25/24.
//

import SwiftUI

struct PromotionBanner: View {
    var body: some View {
        Button {
            print("Nav to appstore")
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
