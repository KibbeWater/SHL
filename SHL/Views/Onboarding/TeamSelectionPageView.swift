//
//  TeamSelectionPageView.swift
//  SHL
//
//  Created by Claude Code
//

import SwiftUI

struct TeamSelectionPageView: View {
    let allTeams: [Team]
    @Binding var selectedTeamIds: Set<String>
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Select Teams to Follow")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Choose the teams you want to track")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !selectedTeamIds.isEmpty {
                    Text("\(selectedTeamIds.count) \(selectedTeamIds.count == 1 ? "team" : "teams") selected")
                        .font(.caption)
                        .foregroundStyle(.accent)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)

            // Team list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(allTeams.filter { !$0.id.isEmpty }.sorted { $0.name < $1.name }) { team in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if selectedTeamIds.contains(team.id) {
                                    selectedTeamIds.remove(team.id)
                                } else {
                                    selectedTeamIds.insert(team.id)
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(team.name)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(team.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if selectedTeamIds.contains(team.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.accent)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if team.id != allTeams.filter { !$0.id.isEmpty }.sorted(by: { $0.name < $1.name }).last?.id {
                            Divider()
                                .padding(.leading, 32)
                        }
                    }
                }
            }

            // Buttons
            VStack(spacing: 12) {
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 48)  // Extra padding for page indicator
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    TeamSelectionPageView(
        allTeams: [],
        selectedTeamIds: .constant([]),
        onContinue: {},
        onSkip: {}
    )
}
