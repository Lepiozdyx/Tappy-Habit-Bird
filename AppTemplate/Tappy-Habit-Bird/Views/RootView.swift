import SwiftUI
import Combine

enum ArcadeRoute {
    case flight
    case newGame
    case scores
    case manual
}

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = HabitGameViewModel()
    @AppStorage("hasSeenGameManual") private var hasSeenGameManual = false
    @State private var route: ArcadeRoute = .flight
    private let calendarCheckTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            currentScreen
                .id(routeKey)
                .transition(.opacity)

            if route == .flight {
                CornerNavigation(
                    openNewGame: { switchRoute(.newGame) },
                    openScores: { switchRoute(.scores) },
                    openManual: { switchRoute(.manual) }
                )
            } else {
                BackCornerButton { switchRoute(.flight) }
            }

            if let medal = viewModel.unlockedMedal {
                ArcadeToast(
                    title: "MEDAL UNLOCKED",
                    message: "\(medal.habitTitle.uppercased()) EARNED \(medal.medal.title.uppercased())",
                    buttonTitle: "OK"
                ) {
                    viewModel.unlockedMedal = nil
                }
                .zIndex(20)
            }
        }
        .environmentObject(viewModel)
        .task { await viewModel.load() }
        .onAppear {
            if !hasSeenGameManual {
                route = .manual
                hasSeenGameManual = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.load() }
            }
        }
        .onReceive(calendarCheckTimer) { _ in
            if scenePhase == .active {
                viewModel.refreshCalendarState()
            }
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch route {
        case .flight:
            FlightDeckView(openNewGame: { switchRoute(.newGame) })
        case .newGame:
            NewGameView(onCreated: { switchRoute(.flight) })
        case .scores:
            HighScoresView()
        case .manual:
            GameManualView()
        }
    }

    private var routeKey: String {
        switch route {
        case .flight: "flight"
        case .newGame: "new-game"
        case .scores: "scores"
        case .manual: "manual"
        }
    }

    private func switchRoute(_ next: ArcadeRoute) {
        withAnimation(.easeInOut(duration: 0.22)) {
            route = next
        }
    }
}

private struct CornerNavigation: View {
    let openNewGame: () -> Void
    let openScores: () -> Void
    let openManual: () -> Void

    var body: some View {
        VStack {
            HStack {
                CornerAssetButton(asset: "app_logo", action: openNewGame)
                Spacer()
                CornerAssetButton(asset: "medal_gold", action: openScores)
            }
            Spacer()
            HStack {
                Spacer()
                CornerAssetButton(asset: "manual_scroll_background", action: openManual)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 22)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private struct CornerAssetButton: View {
    let asset: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PixelAssetView(name: asset, mode: .contain, bordered: false)
                .frame(width: 58, height: 58)
                .padding(8)
                .background(Color.white.opacity(0.22))
                .overlay(Rectangle().stroke(.black, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(asset)
    }
}

private struct BackCornerButton: View {
    let action: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: action) {
                    ZStack {
                        Color(red: 0.88, green: 0.93, blue: 0.72)
                        OutlinedText(text: "<", size: 36, color: .white)
                    }
                    .frame(width: 54, height: 54)
                    .overlay(Rectangle().stroke(.black, lineWidth: 3))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }
}
