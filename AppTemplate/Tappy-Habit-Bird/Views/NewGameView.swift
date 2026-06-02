import SwiftUI

struct NewGameView: View {
    let onCreated: () -> Void

    @EnvironmentObject private var viewModel: HabitGameViewModel
    @FocusState private var titleFocused: Bool

    @State private var title = ""
    @State private var category: HabitCategory = .health
    @State private var avatar: HabitAvatar = .yellowBird
    @State private var selectedTemplate: HabitTemplate?
    @State private var validationMessage: String?

    var body: some View {
        ArcadeScreen {
            VStack(spacing: 0) {
                CenteredArcadeTitle(text: "NEW GAME")

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            PixelPanel(background: Color(red: 0.78, green: 0.9, blue: 0.78)) {
                                VStack(alignment: .leading, spacing: 14) {
                                    ArcadeTextField(title: "QUEST NAME", text: $title, focused: $titleFocused)
                                        .id("questNameField")
                                        .onChange(of: title) { _, newValue in
                                            if newValue.count > 24 {
                                                title = String(newValue.prefix(24))
                                            }
                                            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                validationMessage = validationMessage == nil ? nil : "Name the quest before launch"
                                            } else {
                                                validationMessage = nil
                                            }
                                        }

                                    HStack {
                                        OutlinedText(text: "\(title.count)/24", size: 17, color: Color(red: 1, green: 0.95, blue: 0.64))
                                        Spacer()
                                        Button("DONE") { titleFocused = false }
                                            .buttonStyle(PixelButtonStyle(background: Color(red: 0.71, green: 0.83, blue: 0.7), compact: true))
                                    }

                                    if let validationMessage {
                                        OutlinedText(text: validationMessage.uppercased(), size: 20, color: Color(red: 1, green: 0.38, blue: 0.34), alignment: .leading)
                                    }
                                }
                            }

                            TemplateDropdown(selection: $selectedTemplate) { template in
                                title = template.title
                                category = template.category
                            }
                            CategoryDropdown(selection: $category)
                            AvatarSelector(selection: $avatar)

                            Button("INSERT COIN") {
                                save(scrollToName: {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        proxy.scrollTo("questNameField", anchor: .center)
                                    }
                                })
                            }
                            .buttonStyle(PixelButtonStyle(background: Color(red: 1.0, green: 0.69, blue: 0.28)))
                            .padding(.bottom, 24)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 88)
                        .padding(.bottom, 110)
                    }
                }
            }
        }
    }

    private func save(scrollToName: () -> Void) {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            validationMessage = "Name the quest before launch"
            titleFocused = true
            scrollToName()
            return
        }
        guard cleanedTitle.count <= 24 else {
            validationMessage = "Quest name must fit in 24 chars"
            return
        }

        viewModel.createHabit(title: cleanedTitle, category: category, avatar: avatar)
        title = ""
        validationMessage = nil
        titleFocused = false
        onCreated()
    }
}

private struct TemplateDropdown: View {
    @Binding var selection: HabitTemplate?
    let apply: (HabitTemplate) -> Void
    @State private var isOpen = false

    var body: some View {
        PixelPanel(background: Color(red: 0.88, green: 0.92, blue: 0.72)) {
            VStack(alignment: .leading, spacing: 12) {
                OutlinedText(text: "STARTER QUESTS", size: 26, color: Color(red: 1, green: 0.96, blue: 0.62), alignment: .leading)
                ArcadeDropdown(
                    isOpen: $isOpen,
                    title: selection?.title.uppercased() ?? "CHOOSE A PRESET",
                    iconAsset: selection?.category.assetName,
                    maxListHeight: 260
                ) {
                    ForEach(HabitTemplate.starterTemplates) { template in
                        ArcadeDropdownRow(
                            title: template.title.uppercased(),
                            iconAsset: template.category.assetName,
                            isSelected: selection?.id == template.id
                        ) {
                            selection = template
                            apply(template)
                            isOpen = false
                        }
                    }
                }
            }
        }
    }
}

private struct CategoryDropdown: View {
    @Binding var selection: HabitCategory
    @State private var isOpen = false

    var body: some View {
        PixelPanel(background: Color(red: 0.79, green: 0.9, blue: 0.91)) {
            VStack(alignment: .leading, spacing: 12) {
                OutlinedText(text: "CATEGORY", size: 26, color: Color(red: 1, green: 0.96, blue: 0.62), alignment: .leading)
                ArcadeDropdown(
                    isOpen: $isOpen,
                    title: selection.title.uppercased(),
                    iconAsset: selection.assetName,
                    maxListHeight: 260
                ) {
                    ForEach(HabitCategory.allCases) { item in
                        ArcadeDropdownRow(
                            title: item.title.uppercased(),
                            iconAsset: item.assetName,
                            isSelected: selection == item
                        ) {
                            selection = item
                            isOpen = false
                        }
                    }
                }
            }
        }
    }
}

private struct ArcadeDropdown<Content: View>: View {
    @Binding var isOpen: Bool
    let title: String
    let iconAsset: String?
    var maxListHeight: CGFloat = 220
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isOpen.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    if let iconAsset {
                        PixelAssetView(name: iconAsset, mode: .contain, bordered: false)
                            .frame(width: 32, height: 32)
                    }
                    OutlinedText(text: title, size: 22, color: .white, alignment: .leading, lineLimit: 1)
                    Spacer()
                    OutlinedText(text: isOpen ? "▲" : "▼", size: 18, color: Color(red: 1, green: 0.94, blue: 0.58), lineLimit: 1)
                }
                .padding(10)
                .frame(minHeight: 54)
                .background(Color(red: 0.53, green: 0.68, blue: 0.62))
                .overlay(Rectangle().stroke(.black, lineWidth: 3))
            }
            .buttonStyle(.plain)

            if isOpen {
                ScrollView {
                    VStack(spacing: 0) {
                        content
                    }
                    .padding(6)
                }
                .frame(maxHeight: maxListHeight)
                .background(Color(red: 0.83, green: 0.88, blue: 0.74))
                .overlay(Rectangle().stroke(.black, lineWidth: 3))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct ArcadeDropdownRow: View {
    let title: String
    let iconAsset: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                PixelAssetView(name: iconAsset, mode: .contain, bordered: false)
                    .frame(width: 30, height: 30)
                OutlinedText(text: title, size: 20, color: .white, alignment: .leading, lineLimit: 2)
                Spacer()
                if isSelected {
                    OutlinedText(text: "OK", size: 17, color: Color(red: 1, green: 0.95, blue: 0.58), lineLimit: 1)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isSelected ? Color(red: 1, green: 0.74, blue: 0.34) : Color.white.opacity(0.18))
            .overlay(Rectangle().stroke(.black, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

private struct AvatarSelector: View {
    @Binding var selection: HabitAvatar

    var body: some View {
        PixelPanel(background: Color(red: 0.9, green: 0.82, blue: 0.91)) {
            VStack(alignment: .leading, spacing: 12) {
                OutlinedText(text: "AVATAR", size: 26, color: Color(red: 1, green: 0.96, blue: 0.62), alignment: .leading)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 12)], spacing: 12) {
                    ForEach(HabitAvatar.allCases) { option in
                        Button {
                            selection = option
                        } label: {
                            VStack(spacing: 6) {
                                PixelAssetView(name: option.assetName, mode: .contain, bordered: false)
                                    .frame(height: 70)
                                OutlinedText(text: option.shortTitle.uppercased(), size: 15, color: .white, lineLimit: 1)
                            }
                            .padding(7)
                            .background(selection == option ? Color(red: 1, green: 0.76, blue: 0.34) : Color.white.opacity(0.24))
                            .overlay(Rectangle().stroke(.black, lineWidth: selection == option ? 3 : 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
