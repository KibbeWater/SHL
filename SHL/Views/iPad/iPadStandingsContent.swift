//
//  iPadStandingsContent.swift
//  SHL
//
//  Standalone standings view for iPad content column
//

import SwiftUI

struct iPadStandingsContent: View {
    @ObservedObject var viewModel: HomeViewModel
    var onSelectTeam: (Team) -> Void

    var body: some View {
        ScrollView {
            if viewModel.standingsDisabled {
                ContentUnavailableView(
                    "Standings Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Standings are temporarily unavailable. We apologize for the inconvenience.")
                )
            } else if let standings = viewModel.standings {
                StandingsTable(
                    title: "SHL Standings",
                    items: standings,
                    favoriteTeamId: Settings.shared.getFavoriteTeamId()
                )
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
        .refreshable {
            try? await viewModel.refresh(hard: true)
        }
    }
}
