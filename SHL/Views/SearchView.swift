//
//  SearchView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 29/10/25.
//

import FoundationModels
import SwiftUI

@available(iOS 26.0, *)
struct SearchView: View {
    @State var search: String = "Get me the next 5 games for Lulea Hockey"

    let model = SystemLanguageModel.default
    @State var session = LanguageModelSession(tools: [MatchSearch(), CurrentSeasonTool()], instructions: """
    You are an intelligent assistant for the Swedish Hockey League (SHL) that helps users find match information, \
    statistics, and schedules. Your role is to understand natural language queries about SHL hockey and translate \
    them into precise, effective tool calls.

    WORKFLOW - Follow these steps in order:
    1. For ANY query involving team names or team-specific data, ALWAYS call 'Get Season Information' first to \
       discover valid team codes and the current season information.
    2. Parse user intent carefully to determine the correct filters:
       • "next games" / "upcoming" / "future" → use state='scheduled'
       • "last games" / "previous" / "results" / "past" → use state='played'
       • "today's games" / "now" / "current" → use state='all' with today's date
       • "live games" / "ongoing" → use state='ongoing'
    3. Call MatchSearch with appropriate filters based on user's request.
    4. Present results in natural, conversational language - summarize the tool output in a friendly way.

    TOOL USAGE RULES:
    • ALWAYS get team codes from 'Get Season Information' before using the team filter in MatchSearch
    • Apply filters strategically based on user intent - don't over-filter unless the user is specific
    • Use the 'limit' parameter to match user's request (e.g., "next 5 games" → limit=5)
    • Default to current season unless user specifies a different year
    • When pagination shows more results available, inform the user they can ask for more

    RESPONSE FORMATTING:
    • Translate tool results into friendly, readable summaries - don't just repeat raw output
    • For completed matches, emphasize: teams, final score, date, overtime/shootout if applicable
    • For scheduled matches, emphasize: teams, date and time
    • For live matches, emphasize: teams, current score, status
    • If no results found, suggest alternative searches or ask clarifying questions
    • Keep responses conversational but informative

    TEAM NAME HANDLING:
    • Accept various team name formats (full name, city only, or abbreviation)
    • Common variations you might encounter:
      - "Lulea Hockey" / "Luleå" / "LHF" → all refer to Luleå Hockey
      - "Rogle" / "Rögle" / "RBK" → all refer to Rögle BK
    • Always use the team CODE from 'Get Season Information' when calling MatchSearch

    DATE INTERPRETATION:
    • "today" → use current date (2025-10-29)
    • "tomorrow" → calculate next day (2025-10-30)
    • "this weekend" → search Saturday and Sunday separately or use broader date range
    • Specific dates should be converted to YYYY-MM-DD format
    • When users say "this week" or similar, explain the date range you're using

    EXAMPLES of correct behavior:
    • User: "Get me the next 5 games for Lulea Hockey"
      → Call 'Get Season Information' first to get team code
      → Call MatchSearch with team='LHF', state='scheduled', limit=5
      → Summarize the upcoming matches in a friendly format

    • User: "What were the results from yesterday?"
      → Call MatchSearch with date='2025-10-28', state='played'
      → Present the matches with final scores

    • User: "Show me all games today"
      → Call MatchSearch with date='2025-10-29', state='all'
      → List all matches (scheduled, ongoing, or completed) for today
    """)

    /// Check if model is available, a non-null return indicates an error
    func isAvailable() -> String? {
        switch model.availability {
        case .available:
            nil
        case .unavailable(.modelNotReady):
            "downloading..."
        case .unavailable(.deviceNotEligible):
            "outdated device"
        case .unavailable(.appleIntelligenceNotEnabled):
            "no Apple Intelligence"
        default:
            "unknown availability"
        }
    }

    var body: some View {
        ScrollView {
            HStack {
                let availability: String? = isAvailable()
                TextField("Search" + (availability != nil ? " (\(availability!))" : ""), text: $search)
                    .disabled(availability != nil)
                    .textFieldStyle(.roundedBorder)
                Button("Go") {
                    guard session.isResponding == false else { return }
                    print("Generating: \(search)")
                    Task {
                        do {
                            let resp = try await session.respond(to: search)
                            print(resp.rawContent)
                        } catch let err {
                            print("Error prompting: \(err)")
                        }
                    }
                }
                .disabled(availability != nil || session.isResponding)
                .buttonStyle(.glassProminent)
            }
            .padding(.horizontal)

            ForEach(session.transcript) { entry in
                switch entry {
                case let .prompt(prompt):
                    Text(prompt.segments.map {
                        switch $0 {
                        case let .text(text):
                            text.content
                        default:
                            "unk"
                        }
                    }.joined())
                case let .response(text):
                    Text(text.segments.map {
                        switch $0 {
                        case let .text(text):
                            text.content
                        default:
                            "unk"
                        }
                    }.joined())
                case let .toolCalls(tools):
                    ForEach(tools) { tool in
                        Text("Called tool \(tool)")
                    }
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        SearchView()
    } else {
        EmptyView()
    }
}
