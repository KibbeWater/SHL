//
//  TeamSelectionSheet.swift
//  SHL
//
//  Created by Claude Code
//

import SwiftUI

struct TeamSelectionSheet: View {
    let allTeams: [Team]
    @State var selectedTeamIds: Set<String>
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    init(allTeams: [Team], selectedTeamIds: [String], onSave: @escaping ([String]) -> Void) {
        self.allTeams = allTeams
        self._selectedTeamIds = State(initialValue: Set(selectedTeamIds))
        self.onSave = onSave
    }

    private var sortedTeams: [Team] {
        allTeams.filter { !$0.id.isEmpty }.sorted { $0.name < $1.name }
    }

    private var filteredTeams: [Team] {
        guard !searchText.isEmpty else { return sortedTeams }
        return sortedTeams.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedTeams.isEmpty {
                    ContentUnavailableView(
                        "No Teams Available",
                        systemImage: "person.2.slash",
                        description: Text("Teams couldn't be loaded right now. Check your connection and try again.")
                    )
                } else if filteredTeams.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    teamList
                }
            }
            .navigationTitle("Interested Teams")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search teams")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(Array(selectedTeamIds))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.selection, trigger: selectedTeamIds)
        }
    }

    private var teamList: some View {
        List {
            Section {
                ForEach(filteredTeams) { team in
                    teamRow(team)
                }
            } header: {
                HStack {
                    Text("Select teams to follow")
                    Spacer()
                    if !selectedTeamIds.isEmpty {
                        Text("\(selectedTeamIds.count) selected")
                            .foregroundStyle(.tint)
                            .textCase(nil)
                    }
                }
            } footer: {
                Text("You'll receive notifications for matches involving your selected teams.")
            }
        }
    }

    private func teamRow(_ team: Team) -> some View {
        let isSelected = selectedTeamIds.contains(team.id)
        return Button {
            withAnimation(.snappy(duration: 0.18)) {
                if isSelected {
                    selectedTeamIds.remove(team.id)
                } else {
                    selectedTeamIds.insert(team.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                TeamLogoView(team: team, size: .custom(34))
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text(team.name)
                        .foregroundStyle(.primary)
                    if let city = team.city, !city.isEmpty {
                        Text(city)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(rowBackground(isSelected))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(team.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func rowBackground(_ selected: Bool) -> some View {
        if selected {
            ZStack {
                Color(.secondarySystemGroupedBackground)
                Color.accentColor.opacity(0.10)
            }
        } else {
            Color(.secondarySystemGroupedBackground)
        }
    }
}

#Preview {
    TeamSelectionSheet(
        allTeams: [
            Team(id: "1", name: "Luleå HF", code: "LHF", city: "Luleå", founded: 1977, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: nil, isActive: true),
            Team(id: "2", name: "Frölunda HC", code: "FHC", city: "Göteborg", founded: 1944, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: nil, isActive: true),
            Team(id: "3", name: "Skellefteå AIK", code: "SKE", city: "Skellefteå", founded: 1921, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: nil, isActive: true)
        ],
        selectedTeamIds: ["1"],
        onSave: { _ in }
    )
}
