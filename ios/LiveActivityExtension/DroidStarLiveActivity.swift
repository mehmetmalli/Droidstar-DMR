/*
    Copyright (C) 2026 DroidStar contributors

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import ActivityKit
import SwiftUI
import WidgetKit

// Lock Screen + Dynamic Island UI for the activity started by LiveActivityManager (main app).
// The app sends three states (see updateDynamicIsland() in ui2026/App2026.qml):
//   TX   - own callsign, handle "Transmitting"
//   RX   - caller's callsign, name and country
//   idle - callsign "Awaiting", handle "RX..."

@main
struct DroidStarLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        DroidStarLiveActivity()
    }
}

private extension DroidStarActivityAttributes.ContentState {
    var isTX: Bool { mode == "TX" }
    var isIdle: Bool { !isTX && callsign == "Awaiting" }

    var tint: Color {
        if isTX { return .red }
        return isIdle ? .gray : .green
    }

    var symbol: String {
        if isTX { return "mic.fill" }
        return isIdle ? "antenna.radiowaves.left.and.right" : "speaker.wave.2.fill"
    }

    var title: String { isIdle ? "Listening" : callsign }

    var detail: String {
        if isIdle { return "Waiting for traffic" }
        return [handle, country].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var talkgroup: String { tgid.isEmpty ? "" : "TG \(tgid)" }
}

struct DroidStarLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DroidStarActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(state.mode, systemImage: state.symbol)
                        .font(.headline)
                        .foregroundStyle(state.tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(state.talkgroup)
                        .font(.headline)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 2) {
                        Text(state.title)
                            .font(.title2.bold())
                            .lineLimit(1)
                        Text(state.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: state.symbol)
                    .foregroundStyle(state.tint)
            } compactTrailing: {
                Text(state.isIdle ? state.talkgroup : state.callsign)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .frame(maxWidth: 72)
            } minimal: {
                Image(systemName: state.symbol)
                    .foregroundStyle(state.tint)
            }
            .keylineTint(state.tint)
        }
    }
}

private struct LockScreenView: View {
    let state: DroidStarActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: state.symbol)
                .font(.title2)
                .foregroundStyle(state.tint)
                .frame(width: 44, height: 44)
                .background(state.tint.opacity(0.2), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.title3.bold())
                    .lineLimit(1)
                Text(state.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(state.mode)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(state.tint.opacity(0.25), in: Capsule())
                    .foregroundStyle(state.tint)
                Text(state.talkgroup)
                    .font(.headline)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .foregroundStyle(.white)
    }
}
