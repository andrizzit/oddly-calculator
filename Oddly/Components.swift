import SwiftUI

struct OddlyPalette {
    let dark: Bool
    var background: Color { dark ? Color(hex: 0x1C2421) : Color(hex: 0xF5F1E8) }
    var ink: Color { dark ? Color(hex: 0xF5F1E8) : Color(hex: 0x202522) }
    var secondary: Color { dark ? Color(hex: 0xBEC9C1) : Color(hex: 0x5C655E) }
    var digit: Color { dark ? Color(hex: 0x2B3731) : Color(hex: 0xFFFCF5) }
    var utility: Color { dark ? Color(hex: 0x4B435D) : Color(hex: 0xDCD5F6) }
    var mint: Color { dark ? Color(hex: 0x30463C) : Color(hex: 0xD9E7D8) }
    var orange: Color { Color(hex: 0xF26B38) }
    var orangeInk: Color { Color(hex: 0x202522) }
    var pressedDigit: Color { dark ? Color(hex: 0x53665B) : Color(hex: 0xCEC9BD) }
    var pressedUtility: Color { dark ? Color(hex: 0x75658D) : Color(hex: 0xBDB0DE) }
    var pressedOrange: Color { Color(hex: 0xF8B18F) }
    var line: Color { ink.opacity(dark ? 0.2 : 0.12) }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255, opacity: 1)
    }
}

/// A tiny native-vector companion. No remote assets, timers or distracting loop.
struct OddlyMascot: View {
    var size: CGFloat = 44
    var celebrating = false
    var dark = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(Color(hex: 0x202522))
                .rotationEffect(.degrees(celebrating && !reduceMotion ? 7 : -7))
            HStack(spacing: size * 0.1) {
                eye(rotation: -8)
                eye(rotation: 8)
            }
            .offset(y: -size * 0.045)
            Capsule()
                .fill(Color(hex: 0xF5F1E8))
                .frame(width: size * 0.17, height: size * 0.045)
                .rotationEffect(.degrees(-10))
                .offset(x: size * 0.04, y: size * 0.22)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func eye(rotation: Double) -> some View {
        Capsule()
            .fill(Color(hex: 0xFFFCF5))
            .frame(width: size * 0.22, height: size * 0.32)
            .overlay(alignment: .bottomTrailing) {
                Circle().fill(Color(hex: 0x202522))
                    .frame(width: size * 0.10, height: size * 0.10)
                    .padding(size * 0.025)
            }
            .rotationEffect(.degrees(rotation))
    }
}

/// A native Button with a brief activation highlight, including very quick taps,
/// keyboard shortcuts, and VoiceOver activation. The action is never delayed.
struct FeedbackButton<Label: View>: View {
    let fill: Color
    let pressedFill: Color
    let foreground: Color
    let selected: Bool
    let cornerRadius: CGFloat
    let raised: Bool
    let bordered: Bool
    let action: () -> Void
    let label: Label
    @State private var activation = 0
    @State private var pulseActive = false

    init(fill: Color = .clear, pressedFill: Color, foreground: Color,
         selected: Bool = false, cornerRadius: CGFloat = 14,
         raised: Bool = false, bordered: Bool = false,
         action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.fill = fill
        self.pressedFill = pressedFill
        self.foreground = foreground
        self.selected = selected
        self.cornerRadius = cornerRadius
        self.raised = raised
        self.bordered = bordered
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            pulseActive = true
            activation &+= 1
            action()
        } label: {
            label
        }
        .buttonStyle(PressFeedbackStyle(fill: fill, pressedFill: pressedFill,
                                       foreground: foreground, selected: selected,
                                       cornerRadius: cornerRadius, raised: raised,
                                       bordered: bordered, activated: pulseActive))
        .task(id: activation) {
            guard activation > 0 else { return }
            do {
                try await Task.sleep(for: .milliseconds(80))
                pulseActive = false
            } catch {
                // A newer activation owns the highlight; never clear its pulse.
            }
        }
        .onDisappear { pulseActive = false }
    }
}

private struct PressFeedbackStyle: ButtonStyle {
    let fill: Color
    let pressedFill: Color
    let foreground: Color
    let selected: Bool
    let cornerRadius: CGFloat
    let raised: Bool
    let bordered: Bool
    let activated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let highlighted = configuration.isPressed || activated
        configuration.label
            .foregroundStyle(foreground)
            .background(highlighted ? pressedFill : fill,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(foreground.opacity(selected ? 0.9 : (bordered ? 0.08 : 0)),
                                  lineWidth: selected ? 2 : 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: Color.black.opacity(raised && !highlighted ? 0.04 : 0), radius: 0, y: 3)
            // Immediate color on contact; a gentle release. Keep labels and hit
            // regions stationary, and retain color feedback with Reduce Motion.
            .animation(highlighted || reduceMotion ? nil : .easeOut(duration: 0.16), value: highlighted)
    }
}

struct RoundToolbarButton: View {
    let symbol: String
    let label: String
    let id: String
    let palette: OddlyPalette
    let action: () -> Void

    var body: some View {
        FeedbackButton(fill: palette.digit, pressedFill: palette.pressedDigit,
                       foreground: palette.ink, cornerRadius: 22, bordered: true,
                       action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}
