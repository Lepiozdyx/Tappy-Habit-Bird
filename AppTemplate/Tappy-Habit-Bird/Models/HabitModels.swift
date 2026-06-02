import Foundation
import SwiftUI

enum HabitCategory: String, CaseIterable, Codable, Identifiable {
    case health
    case activity
    case development
    case sleep
    case nutrition
    case mentality
    case focus
    case education
    case home
    case sport
    case productivity
    case society
    case finance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health: "Health"
        case .activity: "Activity"
        case .development: "Development"
        case .sleep: "Sleep"
        case .nutrition: "Nutrition"
        case .mentality: "Mentality"
        case .focus: "Focus"
        case .education: "Education"
        case .home: "Home"
        case .sport: "Sport"
        case .productivity: "Productivity"
        case .society: "Society"
        case .finance: "Finance"
        }
    }

    var symbolName: String {
        switch self {
        case .health: "cross.case.fill"
        case .activity: "figure.walk"
        case .development: "book.fill"
        case .sleep: "moon.stars.fill"
        case .nutrition: "carrot.fill"
        case .mentality: "brain.head.profile"
        case .focus: "iphone.slash"
        case .education: "graduationcap.fill"
        case .home: "house.fill"
        case .sport: "dumbbell.fill"
        case .productivity: "checklist"
        case .society: "hands.sparkles.fill"
        case .finance: "dollarsign.circle.fill"
        }
    }

    var assetName: String {
        "category_\(rawValue)_icon"
    }
}

enum HabitAvatar: String, CaseIterable, Codable, Identifiable {
    case yellowBird
    case blueFish
    case redDragon
    case pixelRobot
    case greenGnome
    case samuraiCat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yellowBird: "Yellow Bird"
        case .blueFish: "Blue Fish"
        case .redDragon: "Red Dragon"
        case .pixelRobot: "Pixel Robot"
        case .greenGnome: "Green Gnome"
        case .samuraiCat: "Samurai Cat"
        }
    }

    var shortTitle: String {
        switch self {
        case .yellowBird: "Bird"
        case .blueFish: "Fish"
        case .redDragon: "Dragon"
        case .pixelRobot: "Robot"
        case .greenGnome: "Gnome"
        case .samuraiCat: "Cat"
        }
    }

    var assetName: String {
        switch self {
        case .yellowBird: "avatar_yellow_bird"
        case .blueFish: "avatar_blue_fish"
        case .redDragon: "avatar_red_dragon"
        case .pixelRobot: "avatar_pixel_robot"
        case .greenGnome: "avatar_green_gnome"
        case .samuraiCat: "avatar_samurai_cat"
        }
    }
}

enum MedalKind: String, CaseIterable, Codable, Identifiable {
    case bronze
    case silver
    case gold
    case platinum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bronze: "Bronze"
        case .silver: "Silver"
        case .gold: "Gold"
        case .platinum: "Platinum"
        }
    }

    var threshold: Int {
        switch self {
        case .bronze: 7
        case .silver: 21
        case .gold: 50
        case .platinum: 100
        }
    }

    var assetName: String {
        "medal_\(rawValue)"
    }

    var tint: Color {
        switch self {
        case .bronze: .brown
        case .silver: .gray
        case .gold: .yellow
        case .platinum: .cyan
        }
    }
}

struct AwardedMedal: Codable, Identifiable, Hashable {
    var id: String { "\(kind.rawValue)-\(unlockedAt.timeIntervalSince1970)" }
    let kind: MedalKind
    let unlockedAt: Date
}

enum HabitDayStatus: String, Codable, Hashable {
    case completed
    case missed
}

struct HabitLogEntry: Codable, Identifiable, Hashable {
    var id: String { dayKey }
    let dayKey: String
    let date: Date
    let status: HabitDayStatus
}

struct Habit: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: HabitCategory
    var avatar: HabitAvatar
    var createdAt: Date
    var currentStreak: Int
    var bestStreak: Int
    var lastCompletedAt: Date?
    var isGameOver: Bool
    var medals: [AwardedMedal]
    var history: [HabitLogEntry]

    init(
        id: UUID = UUID(),
        title: String,
        category: HabitCategory,
        avatar: HabitAvatar,
        createdAt: Date = Date(),
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        lastCompletedAt: Date? = nil,
        isGameOver: Bool = false,
        medals: [AwardedMedal] = [],
        history: [HabitLogEntry] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.avatar = avatar
        self.createdAt = createdAt
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastCompletedAt = lastCompletedAt
        self.isGameOver = isGameOver
        self.medals = medals
        self.history = history
    }
}

struct HabitTemplate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let category: HabitCategory
}

extension HabitTemplate {
    static let starterTemplates: [HabitTemplate] = [
        HabitTemplate(title: "Morning water", category: .health),
        HabitTemplate(title: "10,000 steps", category: .activity),
        HabitTemplate(title: "Read 15 minutes", category: .development),
        HabitTemplate(title: "Sleep before 23:30", category: .sleep),
        HabitTemplate(title: "No sugar today", category: .nutrition),
        HabitTemplate(title: "5-minute meditation", category: .mentality),
        HabitTemplate(title: "Do a workout", category: .activity),
        HabitTemplate(title: "No social media for 1 hour", category: .focus),
        HabitTemplate(title: "Learn 5 new words", category: .education),
        HabitTemplate(title: "Eat vegetables", category: .nutrition),
        HabitTemplate(title: "Clean for 10 minutes", category: .home),
        HabitTemplate(title: "Make the bed", category: .home),
        HabitTemplate(title: "30 push-ups", category: .sport),
        HabitTemplate(title: "Plan tomorrow", category: .productivity),
        HabitTemplate(title: "Walk for 15 minutes", category: .health),
        HabitTemplate(title: "Take vitamins", category: .health),
        HabitTemplate(title: "Drink 2 liters of water", category: .health),
        HabitTemplate(title: "Do a kind thing", category: .society),
        HabitTemplate(title: "Contrast shower", category: .health),
        HabitTemplate(title: "Record daily expenses", category: .finance)
    ]
}

