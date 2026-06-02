import SwiftUI

struct FlightDeckView: View {
    let openNewGame: () -> Void

    @EnvironmentObject private var viewModel: HabitGameViewModel
    @State private var habitToRestart: Habit?

    var body: some View {
        ArcadeScreen {
            content

            if let habitToRestart {
                ArcadeToast(
                    title: "RESTART FLIGHT?",
                    message: "\(habitToRestart.title.uppercased()) CONTINUES FROM SCORE 0. BEST SCORE STAYS.",
                    buttonTitle: "PLAY AGAIN"
                ) {
                    viewModel.restart(habitToRestart)
                    self.habitToRestart = nil
                }
                .onTapGesture {
                    self.habitToRestart = nil
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .loading:
            PixelPanel(background: Color(red: 0.87, green: 0.93, blue: 0.82)) {
                OutlinedText(text: "LOADING SAVED GAME", size: 28, color: .white)
            }
            .padding()
        case .failed(let message):
            PixelPanel(background: Color(red: 0.92, green: 0.64, blue: 0.58)) {
                VStack(spacing: 12) {
                    OutlinedText(text: "LOAD ERROR", size: 32, color: Color(red: 1, green: 0.9, blue: 0.55))
                    OutlinedText(text: message.uppercased(), size: 20, color: .white)
                    Button("RETRY") { viewModel.retryLoad() }
                        .buttonStyle(PixelButtonStyle())
                }
            }
            .padding()
        case .ready:
            if viewModel.habits.isEmpty {
                EmptyFlightView(openNewGame: openNewGame)
            } else {
                GeometryReader { proxy in
                    let previousPanelSpacing = max(72, min(126, proxy.size.height / 7))
                    let panelHeight = previousPanelSpacing * 3 * 0.75
                    let panelSpacing = panelHeight / 3

                    ScrollView {
                        LazyVStack(spacing: panelSpacing) {
                            ForEach(viewModel.habits) { habit in
                                HabitFlightLaneView(habit: habit) {
                                    if habit.isGameOver {
                                        habitToRestart = habit
                                    } else {
                                        viewModel.completeToday(for: habit)
                                    }
                                } restartAction: {
                                    habitToRestart = habit
                                }
                                .frame(height: panelHeight)
                            }
                        }
                        .padding(.top, 88)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 96)
                    }
                }
            }
        }
    }
}

private struct EmptyFlightView: View {
    let openNewGame: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            OutlinedText(text: "NO ACTIVE QUESTS", size: 38, color: Color(red: 1.0, green: 0.95, blue: 0.58), lineLimit: 2)
            Button("START NEW QUEST", action: openNewGame)
                .buttonStyle(PixelButtonStyle(background: Color(red: 0.98, green: 0.72, blue: 0.36)))
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HabitFlightLaneView: View {
    let habit: Habit
    let action: () -> Void
    let restartAction: () -> Void

    @EnvironmentObject private var viewModel: HabitGameViewModel
    @State private var flightProgress: CGFloat = 0
    @State private var jumpOffset: CGFloat = 0
    @State private var isFlying = false

    var body: some View {
        Button {
            guard !viewModel.isCompletedToday(habit), !habit.isGameOver else {
                action()
                return
            }
            flightProgress = 0
            jumpOffset = 0
            isFlying = true
            withAnimation(.linear(duration: 0.82)) {
                flightProgress = 1
            }
            withAnimation(.easeOut(duration: 0.22)) {
                jumpOffset = -64
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.easeIn(duration: 0.44)) {
                    jumpOffset = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.84) {
                action()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.88) {
                flightProgress = 0
                isFlying = false
            }
        } label: {
            ZStack {
                PixelPanel(background: Color(red: 0.88, green: 0.95, blue: 0.86).opacity(0.9), padding: 12) {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(alignment: .top, spacing: 10) {
                            PixelAssetView(name: habit.category.assetName, mode: .contain, bordered: false)
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                OutlinedText(text: habit.title.uppercased(), size: 24, color: .white, alignment: .leading, lineLimit: 2)
                                OutlinedText(text: habit.category.title.uppercased(), size: 16, color: Color(red: 0.92, green: 0.99, blue: 0.68), alignment: .leading, lineLimit: 1)
                            }

                            Spacer()

                            if habit.isGameOver {
                                Button("PLAY AGAIN", action: restartAction)
                                    .buttonStyle(PixelButtonStyle(background: Color(red: 0.88, green: 0.33, blue: 0.33), compact: true))
                            }
                        }

                        Spacer(minLength: 0)

                        FlightRunwayView(
                            habit: habit,
                            progress: displayedProgress,
                            jumpOffset: jumpOffset,
                            dueDateText: viewModel.dueDateText(for: habit),
                            isCleared: viewModel.isCompletedToday(habit),
                            isGameOver: habit.isGameOver
                        )
                        .frame(height: 150)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: .infinity)

                if habit.isGameOver {
                    GameOverOverlay()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(habit.title), current score \(habit.currentStreak), best score \(habit.bestStreak)")
    }

    private var displayedProgress: CGFloat {
        if isFlying { return flightProgress }
        return 0
    }
}

private struct FlightRunwayView: View {
    let habit: Habit
    let progress: CGFloat
    let jumpOffset: CGFloat
    let dueDateText: String
    let isCleared: Bool
    let isGameOver: Bool

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let clamped = min(max(progress, 0), 1)
            let birdX = min(width * 0.06, 18)
            let pipeWidth: CGFloat = 118
            let restingPipeX = max(142, width - pipeWidth - 6)
            let outgoingPipeX = restingPipeX + (-pipeWidth - restingPipeX - 24) * clamped
            let incomingStartX = width + 28
            let incomingPipeX = incomingStartX + (restingPipeX - incomingStartX) * clamped

            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 8)
                    .offset(y: -12)

                PipeScoreView(
                    streak: habit.currentStreak,
                    dateText: dueDateText,
                    isCleared: isCleared,
                    isGameOver: isGameOver
                )
                .frame(width: pipeWidth, height: 148)
                .offset(x: outgoingPipeX)

                PipeScoreView(
                    streak: habit.currentStreak,
                    dateText: "NEXT",
                    isCleared: false,
                    isGameOver: false
                )
                .frame(width: pipeWidth, height: 148)
                .offset(x: incomingPipeX)

                PixelAssetView(name: habit.avatar.assetName, mode: .contain, bordered: false)
                    .frame(width: 88, height: 88)
                    .offset(x: birdX, y: jumpOffset - 34)
                    .zIndex(3)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
            .clipped()
        }
    }
}

private struct GameOverOverlay: View {
    var body: some View {
        ZStack {
            PixelAssetView(name: "game_over_cracks", mode: .cover, bordered: false)
                .opacity(0.78)
            Color.red.opacity(0.18)
            VStack(spacing: -4) {
                OutlinedText(text: "GAME", size: 42, color: Color(red: 1, green: 0.32, blue: 0.3))
                OutlinedText(text: "OVER", size: 42, color: Color(red: 1, green: 0.32, blue: 0.3))
            }
        }
        .overlay(Rectangle().stroke(.black, lineWidth: 3))
    }
}
