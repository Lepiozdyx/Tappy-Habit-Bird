import SwiftUI

enum PixelAssetScaleMode {
    case cover
    case contain
    case fill
}

extension Font {
    static func jersey(_ size: CGFloat) -> Font {
        .custom("Jersey 25", size: size, relativeTo: .body)
    }
}

extension View {
    func arcadeTextStyle(_ color: Color = .white) -> some View {
        font(.jersey(22))
            .foregroundStyle(color)
            .shadow(color: .black, radius: 0, x: 1.2, y: 0)
            .shadow(color: .black, radius: 0, x: -1.2, y: 0)
            .shadow(color: .black, radius: 0, x: 0, y: 1.2)
            .shadow(color: .black, radius: 0, x: 0, y: -1.2)
    }
}

struct OutlinedText: View {
    let text: String
    var size: CGFloat = 22
    var color: Color = .white
    var alignment: TextAlignment = .center
    var lineLimit: Int? = nil

    var body: some View {
        Text(text)
            .font(.jersey(size))
            .foregroundStyle(color)
            .multilineTextAlignment(alignment)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.55)
            .shadow(color: .black, radius: 0, x: 1.5, y: 0)
            .shadow(color: .black, radius: 0, x: -1.5, y: 0)
            .shadow(color: .black, radius: 0, x: 0, y: 1.5)
            .shadow(color: .black, radius: 0, x: 0, y: -1.5)
    }
}

struct PixelAssetView: View {
    let name: String
    let mode: PixelAssetScaleMode
    var cornerRadius: CGFloat = 0
    var bordered: Bool = true

    var body: some View {
        GeometryReader { proxy in
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .interpolation(.none)
                    .modifier(PixelAssetScaleModifier(mode: mode))
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                fallback
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            if bordered {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.black, lineWidth: 3)
            }
        }
    }

    private var fallback: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.32))
            VStack(spacing: 4) {
                OutlinedText(text: "MISSING", size: 13, color: .yellow)
                OutlinedText(text: name, size: 10, color: .white, lineLimit: 3)
                    .padding(.horizontal, 6)
            }
        }
        .accessibilityLabel("Missing asset \(name)")
    }
}

private struct PixelAssetScaleModifier: ViewModifier {
    let mode: PixelAssetScaleMode

    func body(content: Content) -> some View {
        switch mode {
        case .cover:
            content.scaledToFill()
        case .contain:
            content.scaledToFit()
        case .fill:
            content
        }
    }
}

struct PixelButtonStyle: ButtonStyle {
    var background: Color = Color(red: 0.96, green: 0.68, blue: 0.26)
    var foreground: Color = .white
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.jersey(compact ? 18 : 24))
            .foregroundStyle(foreground)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.58)
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.vertical, compact ? 8 : 12)
            .frame(minHeight: compact ? 36 : 48)
            .background(
                ZStack(alignment: .bottom) {
                    Rectangle().fill(background)
                    Rectangle().fill(.white.opacity(0.24)).frame(height: 4).frame(maxHeight: .infinity, alignment: .top)
                    Rectangle().fill(.black.opacity(0.16)).frame(height: 6)
                }
            )
            .overlay(Rectangle().stroke(.black, lineWidth: 3))
            .shadow(color: .black.opacity(configuration.isPressed ? 0 : 0.25), radius: 0, x: 0, y: configuration.isPressed ? 0 : 4)
            .offset(y: configuration.isPressed ? 3 : 0)
    }
}

struct PixelPanel<Content: View>: View {
    var background: Color = Color(red: 0.86, green: 0.92, blue: 0.86)
    var padding: CGFloat = 14
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(background)
            .overlay(Rectangle().stroke(.black, lineWidth: 3))
            .shadow(color: .black.opacity(0.22), radius: 0, x: 4, y: 4)
    }
}

struct ArcadeScreen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            ArcadeBackground()
            content
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct CenteredArcadeTitle: View {
    let text: String

    var body: some View {
        OutlinedText(text: text, size: 34, color: Color(red: 1.0, green: 0.93, blue: 0.58), lineLimit: 1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 72)
            .padding(.top, 10)
    }
}

struct ArcadeBackground: View {
    var isNight: Bool {
        Calendar.current.component(.hour, from: Date()) >= 21 || Calendar.current.component(.hour, from: Date()) < 6
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            PixelAssetView(name: "background_day_sky", mode: .cover, bordered: false)
                .opacity(isNight ? 0.48 : 1)
                .overlay(isNight ? Color(red: 0.04, green: 0.06, blue: 0.18).opacity(0.52) : .clear)

            if UIImage(named: "background_day_sky") == nil {
                LinearGradient(
                    colors: isNight ? [Color(red: 0.05, green: 0.08, blue: 0.18), Color(red: 0.13, green: 0.19, blue: 0.34)] : [Color(red: 0.64, green: 0.88, blue: 0.91), Color(red: 0.8, green: 0.94, blue: 0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            PixelAssetView(name: "environment_ground_bricks", mode: .cover, bordered: false)
                .frame(height: 76)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

struct PipeScoreView: View {
    let streak: Int
    let dateText: String
    let isCleared: Bool
    let isGameOver: Bool

    var body: some View {
        ZStack {
            PixelAssetView(name: "obstacle_pipe_green", mode: .fill, bordered: false)
            VStack(spacing: 8) {
                OutlinedText(text: "[ \(streak) ]", size: 34, color: Color(red: 0.99, green: 0.99, blue: 0.76), lineLimit: 1)
                OutlinedText(text: dateText.uppercased(), size: 17, color: .white, lineLimit: 1)
                OutlinedText(text: statusText, size: 15, color: statusColor, lineLimit: 1)
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current score \(streak), due \(dateText), \(statusText)")
    }

    private var statusText: String {
        if isGameOver { return "GAME OVER" }
        if isCleared { return "CLEARED" }
        return streak == 0 ? "TAP TO BEGIN" : "TAP TODAY"
    }

    private var statusColor: Color {
        isGameOver ? Color(red: 1, green: 0.34, blue: 0.32) : (isCleared ? Color(red: 0.69, green: 1, blue: 0.58) : Color(red: 1, green: 0.82, blue: 0.48))
    }
}

struct ArcadeTextField: View {
    let title: String
    @Binding var text: String
    @FocusState.Binding var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            OutlinedText(text: title, size: 18, color: Color(red: 0.95, green: 0.98, blue: 0.74), alignment: .leading)
            TextField("", text: $text)
                .focused($focused)
                .font(.jersey(24))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.95, green: 0.96, blue: 0.83))
                .overlay(Rectangle().stroke(.black, lineWidth: 3))
                .submitLabel(.done)
        }
    }
}

struct ArcadeToast: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
            PixelPanel(background: Color(red: 0.9, green: 0.93, blue: 0.78)) {
                VStack(spacing: 12) {
                    OutlinedText(text: title, size: 32, color: Color(red: 1, green: 0.86, blue: 0.4), lineLimit: 2)
                    OutlinedText(text: message, size: 22, color: .white)
                    Button(buttonTitle, action: action)
                        .buttonStyle(PixelButtonStyle())
                }
                .frame(maxWidth: 300)
            }
            .padding(28)
        }
        .transition(.opacity)
    }
}

