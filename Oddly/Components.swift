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

struct CalculatorKeyStyle: ButtonStyle {
    let fill: Color
    let foreground: Color
    let selected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(fill, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .strokeBorder(foreground.opacity(selected ? 0.9 : 0.06), lineWidth: selected ? 2 : 1)
            }
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0 : 0.04), radius: 0, y: 3)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.83 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct RoundToolbarButton: View {
    let symbol: String
    let label: String
    let id: String
    let palette: OddlyPalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 44, height: 44)
                .background(palette.digit, in: Circle())
                .overlay(Circle().strokeBorder(palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette.ink)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}
