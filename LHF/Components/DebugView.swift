//
//  DebugView.swift
//  LHF
//
//  Created by user242911 on 1/3/24.
//

import SwiftUI
import HockeyKit

struct DebugView: View {
    var body: some View {
        VStack {
            HStack {
                ScrollView {
                    Text(Logging.shared.getLogs())
                }
                Spacer()
            }
            Spacer()
            Button("Download") {
                
            }
            .buttonStyle(.borderedProminent)
            
        }
        .padding()
    }
}

#Preview {
    DebugView()
}
