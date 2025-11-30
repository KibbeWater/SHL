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

    init(allTeams: [Team], selectedTeamIds: [String], onSave: @escaping ([String]) -> Void) {
        self.allTeams = allTeams
        self._selectedTeamIds = State(initialValue: Set(selectedTeamIds))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
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
                            HStack {
                                Text(team.name)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(team.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if selectedTeamIds.contains(team.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select teams to follow")
                } footer: {
                    Text("You'll receive notifications for matches involving your selected teams.")
                }
            }
            .navigationTitle("Interested Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(Array(selectedTeamIds))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    TeamSelectionSheet(
        allTeams: [],
        selectedTeamIds: [],
        onSave: { _ in }
    )
}
