import SwiftUI

struct HighScoresView: View {
    @EnvironmentObject private var viewModel: HabitGameViewModel
    @State private var editingHabit: Habit?
    @State private var deletingHabit: Habit?

    var body: some View {
        ArcadeScreen {
            VStack(spacing: 0) {
                CenteredArcadeTitle(text: "HIGH SCORES")

                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.habits.isEmpty {
                            PixelPanel(background: Color(red: 0.86, green: 0.92, blue: 0.78)) {
                                OutlinedText(text: "NO SCORES YET", size: 34, color: Color(red: 1, green: 0.95, blue: 0.58))
                            }
                            .padding(.top, 92)
                        } else {
                            activeQuests
                            leaderboard
                            medals
                            weeklyChart
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 88)
                    .padding(.bottom, 104)
                }
            }

            if let editingHabit {
                EditQuestOverlay(habit: editingHabit) {
                    self.editingHabit = nil
                }
                .environmentObject(viewModel)
                .zIndex(10)
            }

            if let deletingHabit {
                ArcadeToast(
                    title: "DELETE QUEST?",
                    message: "\(deletingHabit.title.uppercased()) SCORE HISTORY AND MEDALS WILL BE REMOVED.",
                    buttonTitle: "DELETE"
                ) {
                    viewModel.deleteHabit(deletingHabit)
                    self.deletingHabit = nil
                }
                .onTapGesture {
                    self.deletingHabit = nil
                }
                .zIndex(11)
            }
        }
    }

    private var activeQuests: some View {
        PixelPanel(background: Color(red: 0.8, green: 0.91, blue: 0.82)) {
            VStack(alignment: .leading, spacing: 12) {
                OutlinedText(text: "ACTIVE QUESTS", size: 28, color: Color(red: 1, green: 0.96, blue: 0.62), alignment: .leading)
                ForEach(viewModel.habits) { habit in
                    HStack(spacing: 10) {
                        PixelAssetView(name: habit.avatar.assetName, mode: .contain, bordered: false)
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            OutlinedText(text: habit.title.uppercased(), size: 20, color: .white, alignment: .leading, lineLimit: 1)
                            OutlinedText(text: "CURRENT \(habit.currentStreak)  BEST \(habit.bestStreak)", size: 15, color: Color(red: 0.93, green: 1, blue: 0.7), alignment: .leading, lineLimit: 1)
                        }
                        Spacer()
                        Button("EDIT") { editingHabit = habit }
                            .buttonStyle(PixelButtonStyle(background: Color(red: 0.71, green: 0.83, blue: 0.7), compact: true))
                        Button("DEL") { deletingHabit = habit }
                            .buttonStyle(PixelButtonStyle(background: Color(red: 0.9, green: 0.46, blue: 0.42), compact: true))
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.18))
                    .overlay(Rectangle().stroke(.black, lineWidth: 2))
                }
            }
        }
    }

    private var leaderboard: some View {
        PixelPanel(background: Color(red: 0.12, green: 0.16, blue: 0.14)) {
            VStack(alignment: .leading, spacing: 12) {
                OutlinedText(text: "LEADERBOARD", size: 28, color: Color(red: 1, green: 0.8, blue: 0.36), alignment: .leading)

                ForEach(viewModel.habits.sorted(by: { $0.bestStreak > $1.bestStreak })) { habit in
                    HStack(spacing: 10) {
                        PixelAssetView(name: habit.category.assetName, mode: .contain, bordered: false)
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            OutlinedText(text: habit.title.uppercased(), size: 20, color: .white, alignment: .leading, lineLimit: 1)
                            OutlinedText(text: "CURRENT [ \(habit.currentStreak) ]", size: 15, color: Color(red: 0.66, green: 1, blue: 0.58), alignment: .leading, lineLimit: 1)
                        }
                        Spacer()
                        OutlinedText(text: "BEST [ \(habit.bestStreak) ]", size: 17, color: Color(red: 1, green: 0.92, blue: 0.5), lineLimit: 1)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var medals: some View {
        PixelPanel(background: Color(red: 0.91, green: 0.92, blue: 0.78)) {
            VStack(alignment: .leading, spacing: 12) {
                OutlinedText(text: "MEDALS", size: 28, color: Color(red: 1, green: 0.96, blue: 0.62), alignment: .leading)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.habits) { habit in
                            ForEach(MedalKind.allCases) { medal in
                                MedalSlot(habit: habit, medal: medal)
                            }
                        }
                    }
                }
            }
        }
    }

    private var weeklyChart: some View {
        PixelPanel(background: Color(red: 0.78, green: 0.9, blue: 0.91)) {
            VStack(alignment: .leading, spacing: 12) {
                OutlinedText(text: "7 DAY QUEST BALANCE", size: 26, color: .white, alignment: .leading, lineLimit: 1)
                OutlinedText(text: "DONE MINUS FAILED", size: 17, color: Color(red: 1, green: 0.96, blue: 0.62), alignment: .leading, lineLimit: 1)
                WeeklyQuestChart(entries: viewModel.netQuestTotalsForLastSevenDays())
                    .frame(height: 178)
            }
        }
    }
}

private struct MedalSlot: View {
    let habit: Habit
    let medal: MedalKind

    var unlocked: AwardedMedal? {
        habit.medals.first { $0.kind == medal }
    }

    var body: some View {
        VStack(spacing: 6) {
            PixelAssetView(name: medal.assetName, mode: .contain, bordered: false)
                .frame(width: 72, height: 72)
                .opacity(unlocked == nil ? 0.34 : 1)
                .overlay {
                    if unlocked == nil {
                        OutlinedText(text: "LOCK", size: 18, color: Color(red: 1, green: 0.86, blue: 0.44))
                    }
            }
            OutlinedText(text: medal.title.uppercased(), size: 16, color: medal.tint, lineLimit: 1)
            OutlinedText(text: "\(medal.threshold) DAYS", size: 13, color: .white, lineLimit: 1)
        }
        .frame(width: 100)
    }
}

private struct WeeklyQuestChart: View {
    let entries: [DailyQuestTotal]

    private var maxAbsoluteValue: Int {
        max(1, entries.map { abs($0.value) }.max() ?? 1)
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(axisLabels, id: \.self) { label in
                        OutlinedText(text: label, size: 13, color: Color(red: 1, green: 0.96, blue: 0.62), lineLimit: 1)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 28)

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(entries) { entry in
                        WeeklyQuestBar(entry: entry, maxAbsoluteValue: maxAbsoluteValue)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .background(
                ZStack {
                    PixelAssetView(name: "chart_pixel_grid", mode: .cover, bordered: false)
                        .opacity(UIImage(named: "chart_pixel_grid") == nil ? 0 : 0.32)
                    GridPattern()
                        .stroke(.black.opacity(0.12), lineWidth: 1)
                }
            )
            .overlay(Rectangle().stroke(.black, lineWidth: 2))
        }
    }

    private var axisLabels: [String] {
        let maxValue = maxAbsoluteValue
        if maxValue == 1 { return ["1", "0"] }
        return [String(maxValue), String(maxValue / 2), "0"]
    }
}

private struct WeeklyQuestBar: View {
    let entry: DailyQuestTotal
    let maxAbsoluteValue: Int

    var body: some View {
        GeometryReader { proxy in
            let chartHeight = max(1, proxy.size.height - 40)
            let ratio = CGFloat(abs(entry.value)) / CGFloat(maxAbsoluteValue)
            let barHeight = entry.value == 0 ? 5 : max(10, chartHeight * ratio)
            let color = entry.value < 0 ? Color(red: 0.95, green: 0.32, blue: 0.3) : Color(red: 0.45, green: 0.9, blue: 0.42)

            VStack(spacing: 4) {
                Spacer(minLength: 0)
                OutlinedText(text: "\(entry.value)", size: 14, color: .white, lineLimit: 1)
                Rectangle()
                    .fill(color)
                    .frame(width: max(12, proxy.size.width * 0.7), height: barHeight)
                    .overlay(Rectangle().stroke(.black.opacity(0.55), lineWidth: 2))
                OutlinedText(text: entry.dayLabel, size: 13, color: .white, lineLimit: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityLabel("\(entry.dayLabel), quest balance \(entry.value)")
    }
}

private struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 12
        var x: CGFloat = 0
        while x <= rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += step
        }
        var y: CGFloat = 0
        while y <= rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += step
        }
        return path
    }
}

private struct EditQuestOverlay: View {
    let habit: Habit
    let close: () -> Void

    @EnvironmentObject private var viewModel: HabitGameViewModel
    @FocusState private var focused: Bool
    @State private var title: String
    @State private var category: HabitCategory
    @State private var avatar: HabitAvatar
    @State private var validationMessage: String?

    init(habit: Habit, close: @escaping () -> Void) {
        self.habit = habit
        self.close = close
        _title = State(initialValue: habit.title)
        _category = State(initialValue: habit.category)
        _avatar = State(initialValue: habit.avatar)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
            ScrollView {
                PixelPanel(background: Color(red: 0.84, green: 0.9, blue: 0.78)) {
                    VStack(spacing: 14) {
                        OutlinedText(text: "EDIT QUEST", size: 34, color: Color(red: 1, green: 0.95, blue: 0.58))
                        ArcadeTextField(title: "QUEST NAME", text: $title, focused: $focused)
                        CategoryMiniSelector(selection: $category)
                        AvatarMiniSelector(selection: $avatar)
                        if let validationMessage {
                            OutlinedText(text: validationMessage.uppercased(), size: 18, color: Color(red: 1, green: 0.36, blue: 0.32))
                        }
                        HStack {
                            Button("CANCEL", action: close)
                                .buttonStyle(PixelButtonStyle(background: Color(red: 0.72, green: 0.8, blue: 0.68), compact: true))
                            Button("SAVE") { save() }
                                .buttonStyle(PixelButtonStyle(compact: true))
                        }
                    }
                }
                .padding(22)
                .padding(.top, 80)
            }
        }
    }

    private func save() {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            validationMessage = "Name the quest"
            return
        }
        viewModel.updateHabit(habit, title: String(cleanedTitle.prefix(24)), category: category, avatar: avatar)
        close()
    }
}

private struct CategoryMiniSelector: View {
    @Binding var selection: HabitCategory

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
            ForEach(HabitCategory.allCases) { item in
                Button { selection = item } label: {
                    PixelAssetView(name: item.assetName, mode: .contain, bordered: false)
                        .frame(width: 34, height: 34)
                        .padding(6)
                        .background(selection == item ? Color(red: 1, green: 0.76, blue: 0.34) : Color.white.opacity(0.2))
                        .overlay(Rectangle().stroke(.black, lineWidth: selection == item ? 3 : 2))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct AvatarMiniSelector: View {
    @Binding var selection: HabitAvatar

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
            ForEach(HabitAvatar.allCases) { item in
                Button { selection = item } label: {
                    PixelAssetView(name: item.assetName, mode: .contain, bordered: false)
                        .frame(width: 54, height: 54)
                        .padding(4)
                        .background(selection == item ? Color(red: 1, green: 0.76, blue: 0.34) : Color.white.opacity(0.2))
                        .overlay(Rectangle().stroke(.black, lineWidth: selection == item ? 3 : 2))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
