import Foundation
import SwiftUI
import Combine

@MainActor
final class HabitGameViewModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case ready
        case failed(String)
    }

    @Published private(set) var habits: [Habit] = []
    @Published private(set) var loadState: LoadState = .loading
    @Published var successMessage: String?
    @Published var unlockedMedal: (habitTitle: String, medal: MedalKind)?

    private let store: HabitStore
    private let calendar: Calendar

    init(store: HabitStore = HabitStore(), calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar
    }

    func load() async {
        loadState = .loading
        do {
            habits = try await store.load()
            evaluateMissedDays()
            try await save()
            loadState = .ready
        } catch {
            habits = []
            loadState = .failed(error.localizedDescription)
        }
    }

    func retryLoad() {
        Task { await load() }
    }

    func refreshCalendarState() {
        evaluateMissedDays()
        Task { try? await save() }
    }

    func createHabit(title: String, category: HabitCategory, avatar: HabitAvatar) {
        let habit = Habit(title: title.trimmingCharacters(in: .whitespacesAndNewlines), category: category, avatar: avatar)
        habits.insert(habit, at: 0)
        successMessage = "New quest inserted."
        Task { try? await save() }
    }

    func updateHabit(_ habit: Habit, title: String, category: HabitCategory, avatar: HabitAvatar) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        habits[index].category = category
        habits[index].avatar = avatar
        successMessage = "Quest updated."
        Task { try? await save() }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        successMessage = "Quest deleted."
        Task { try? await save() }
    }

    func completeToday(for habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        guard !isCompletedToday(habits[index]) else {
            successMessage = "Today's pipe is already cleared."
            return
        }
        guard !habits[index].isGameOver else {
            successMessage = "Press Play Again before flying."
            return
        }

        let now = Date()
        let todayKey = dayKey(for: now)
        habits[index].currentStreak += 1
        habits[index].bestStreak = max(habits[index].bestStreak, habits[index].currentStreak)
        habits[index].lastCompletedAt = now
        habits[index].history.removeAll { $0.dayKey == todayKey }
        habits[index].history.append(HabitLogEntry(dayKey: todayKey, date: startOfDay(now), status: .completed))
        habits[index].history.sort { $0.date < $1.date }

        if let medal = newlyUnlockedMedal(for: habits[index]) {
            habits[index].medals.append(AwardedMedal(kind: medal, unlockedAt: now))
            unlockedMedal = (habits[index].title, medal)
        } else {
            successMessage = "Pipe cleared. Score \(habits[index].currentStreak)."
        }

        Task { try? await save() }
    }

    func restart(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isGameOver = false
        habits[index].currentStreak = 0
        successMessage = "Ready for a new flight."
        Task { try? await save() }
    }

    func isCompletedToday(_ habit: Habit) -> Bool {
        guard let lastCompletedAt = habit.lastCompletedAt else { return false }
        return calendar.isDateInToday(lastCompletedAt)
    }

    func dueDateText(for habit: Habit) -> String {
        if isCompletedToday(habit), let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
            return tomorrow.formatted(.dateTime.day().month(.abbreviated))
        }
        return Date().formatted(.dateTime.day().month(.abbreviated))
    }

    func lastThirtyDays(for habit: Habit) -> [HabitLogEntry] {
        let today = startOfDay(Date())
        let known = Dictionary(uniqueKeysWithValues: habit.history.map { ($0.dayKey, $0) })

        return (0..<30).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -29 + offset, to: today) else {
                return nil
            }
            let key = dayKey(for: date)
            return known[key] ?? HabitLogEntry(dayKey: key, date: date, status: .missed)
        }
    }

    func netQuestTotalsForLastSevenDays() -> [DailyQuestTotal] {
        let today = startOfDay(Date())

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else {
                return nil
            }

            let key = dayKey(for: date)
            let completed = habits.reduce(0) { total, habit in
                total + habit.history.filter { $0.dayKey == key && $0.status == .completed }.count
            }
            let missed = habits.reduce(0) { total, habit in
                total + habit.history.filter { $0.dayKey == key && $0.status == .missed }.count
            }

            return DailyQuestTotal(date: date, value: completed - missed)
        }
    }

    private func evaluateMissedDays() {
        let today = startOfDay(Date())

        for index in habits.indices {
            guard let lastCompletedAt = habits[index].lastCompletedAt else { continue }
            let lastDay = startOfDay(lastCompletedAt)
            guard lastDay < today else { continue }

            let daysMissed = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            guard daysMissed > 0 else { continue }

            for dayOffset in 1...daysMissed {
                guard let missedDate = calendar.date(byAdding: .day, value: dayOffset, to: lastDay), missedDate < today else {
                    continue
                }
                let key = dayKey(for: missedDate)
                if !habits[index].history.contains(where: { $0.dayKey == key }) {
                    habits[index].history.append(HabitLogEntry(dayKey: key, date: missedDate, status: .missed))
                }
            }

            if habits[index].currentStreak > 0 {
                habits[index].currentStreak = 0
                habits[index].isGameOver = true
            }
            habits[index].history.sort { $0.date < $1.date }
        }
    }

    private func newlyUnlockedMedal(for habit: Habit) -> MedalKind? {
        MedalKind.allCases.first { medal in
            habit.currentStreak == medal.threshold && !habit.medals.contains { $0.kind == medal }
        }
    }

    private func save() async throws {
        do {
            try await store.save(habits)
        } catch {
            loadState = .failed(error.localizedDescription)
            throw error
        }
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func dayKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

struct DailyQuestTotal: Identifiable, Hashable {
    var id: String { dayLabel }
    let date: Date
    let value: Int

    var dayLabel: String {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        return String(format: "%02d.%02d", components.month ?? 0, components.day ?? 0)
    }
}
