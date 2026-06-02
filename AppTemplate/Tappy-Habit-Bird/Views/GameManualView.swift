import SwiftUI

struct GameManualView: View {
    private let rules: [(String, String, String)] = [
        ("manual_rule_tap_icon", "TAP = FLIGHT", "ONE TAP CLEARS TODAY'S PIPE FOR THAT QUEST."),
        ("manual_rule_miss_icon", "MISS = CRASH", "AT 00:00, AN UNCLEARED DAY BREAKS THE STREAK."),
        ("manual_rule_best_icon", "BEST SCORE STAYS", "GAME OVER RESETS CURRENT SCORE, NEVER THE RECORD."),
        ("manual_rule_medal_icon", "MEDALS UNLOCK", "BRONZE 7, SILVER 21, GOLD 50, PLATINUM 100 DAYS."),
        ("manual_rule_restart_icon", "PLAY AGAIN", "RESTART AFTER GAME OVER AND KEEP FLYING."),
        ("manual_rule_no_backfill_icon", "NO BACKFILL", "PAST DAYS CANNOT BE MARKED LATER.")
    ]

    var body: some View {
        ArcadeScreen {
            VStack(spacing: 0) {
                CenteredArcadeTitle(text: "RULES")

                ScrollView {
                    PixelPanel(background: Color(red: 0.91, green: 0.9, blue: 0.7)) {
                        VStack(alignment: .leading, spacing: 14) {
                            OutlinedText(text: "GAME MANUAL", size: 34, color: Color(red: 1, green: 0.95, blue: 0.58), alignment: .leading)
                            OutlinedText(text: "FLY TOWARD THE GOAL. DO NOT MISS A DAY. DO NOT CRASH INTO LAZINESS.", size: 22, color: .white, alignment: .leading)

                            ForEach(rules, id: \.1) { icon, title, body in
                                HStack(alignment: .top, spacing: 10) {
                                    PixelAssetView(name: icon, mode: .contain, bordered: false)
                                        .frame(width: 42, height: 42)
                                        .padding(4)
                                        .background(Color.white.opacity(0.22))
                                        .overlay(Rectangle().stroke(.black, lineWidth: 2))
                                    VStack(alignment: .leading, spacing: 2) {
                                        OutlinedText(text: title, size: 24, color: Color(red: 0.98, green: 0.78, blue: 0.38), alignment: .leading)
                                        OutlinedText(text: body, size: 19, color: .white, alignment: .leading)
                                    }
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.18))
                                .overlay(Rectangle().stroke(.black, lineWidth: 2))
                            }
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 78)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        PixelAssetView(name: "manual_scroll_background", mode: .contain, bordered: false)
                            .frame(width: 132, height: 132)
                            .offset(x: 36, y: 38)
                            .allowsHitTesting(false)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 88)
                    .padding(.bottom, 110)
                }
            }
        }
    }
}
