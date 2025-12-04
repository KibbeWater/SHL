//
//  WelcomePageView.swift
//  SHL
//
//  Created by Claude Code
//

import SwiftUI

struct WelcomePageView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App branding
            Text("SHL")
                .font(.system(size: 72, weight: .heavy))
                .foregroundStyle(.primary)

            VStack(spacing: 16) {
                Text("Welcome to SHL")
                    .font(.title.bold())

                Text("Follow your favorite teams and never miss a moment")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Get Started button
            Button {
                onContinue()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    WelcomePageView(onContinue: {})
}
