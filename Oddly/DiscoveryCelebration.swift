import SwiftUI
import CalculatorCore

/// The Tiny Victory Department: a one-off costume for a newly discovered curiosity.
/// Attach to the 44-point mascot. Its entire drawing fits inside 56 × 64 points,
/// leaving the companion's text and keypad untouched. It never handles input.
struct DiscoveryCelebration: View {
    let trigger: Int
    let mode: PersonalityMode

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var previousTrigger: Int
    @State private var visible = false
    @State private var launched = false

    init(trigger: Int, mode: PersonalityMode) {
        self.trigger = trigger
        self.mode = mode
        // Mounting/reappearing with a previously earned discovery does not replay it.
        _previousTrigger = State(initialValue: trigger)
    }

    var body: some View {
        ZStack {
            if mode != .calm && !reduceMotion {
                sparks
                if mode == .unhinged {
                    tinyColleagues
                    ceremonialMoustache
                }
                partyHat
            }
        }
        .frame(width: 56, height: 64)
        .opacity(visible ? 1 : 0)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: trigger) {
            guard trigger != previousTrigger else { return }
            previousTrigger = trigger
            guard trigger > 0, mode != .calm, !reduceMotion else {
                visible = false
                return
            }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                visible = true
                launched = false
            }
            do {
                // Give the initial positions a frame before their single outward hop.
                try await Task.sleep(for: .milliseconds(20))
                withAnimation(.easeOut(duration: 1.0)) { launched = true }
                try await Task.sleep(for: .milliseconds(1_050))
                withAnimation(.easeOut(duration: 0.16)) { visible = false }
            } catch {
                // SwiftUI cancels the finite task on disappearance or a newer trigger.
            }
        }
    }

    private var partyHat: some View {
        ZStack(alignment: .top) {
            PartyHatShape()
                .fill(Color(hex: mode == .unhinged ? 0xF26B38 : 0xDCD5F6))
                .overlay {
                    PartyHatShape().stroke(Color(hex: 0x202522), lineWidth: 1)
                }
            Circle()
                .fill(Color(hex: 0xF5F1E8))
                .frame(width: 5, height: 5)
                .offset(y: -1)
            Capsule()
                .fill(Color(hex: 0x202522))
                .frame(width: 12, height: 2)
                .rotationEffect(.degrees(-14))
                .offset(x: 1, y: 15)
        }
        .frame(width: 23, height: 22)
        .rotationEffect(.degrees(launched ? 10 : -12))
        .offset(x: 2, y: -20)
    }

    private var ceremonialMoustache: some View {
        HStack(spacing: -1) {
            Capsule().rotationEffect(.degrees(-24))
            Capsule().rotationEffect(.degrees(24))
        }
        .foregroundStyle(Color(hex: 0xF5F1E8))
        .frame(width: 20, height: 5)
        .rotationEffect(.degrees(launched ? -6 : 6))
        .offset(y: 7)
    }

    private var sparks: some View {
        ForEach(0..<6, id: \.self) { index in
            let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
            let row = CGFloat(index / 2)
            Capsule()
                .fill(Color(hex: index.isMultiple(of: 3) ? 0xF26B38 : 0xA399C5))
                .frame(width: 3, height: 5)
                .rotationEffect(.degrees(Double(index * 38) + (launched ? 110 : 0)))
                .offset(x: side * (launched ? 25 : 12),
                        y: launched ? -27 + row * 22 : -9 + row * 8)
                .opacity(launched ? 0 : 1)
        }
    }

    private var tinyColleagues: some View {
        ForEach(0..<3, id: \.self) { index in
            OddlyMascot(size: 10, celebrating: index.isMultiple(of: 2))
                .rotationEffect(.degrees(launched ? Double(index * 30 - 25) : 0))
                .offset(x: colleagueX(index), y: colleagueY(index))
                .opacity(launched ? 0 : 1)
        }
    }

    private func colleagueX(_ index: Int) -> CGFloat {
        let positions: [CGFloat] = [-20, 21, -18]
        return launched ? positions[index] : positions[index] * 0.6
    }

    private func colleagueY(_ index: Int) -> CGFloat {
        let positions: [CGFloat] = [-22, -7, 23]
        return launched ? positions[index] : positions[index] * 0.4
    }
}

private struct PartyHatShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY + 1))
            path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.maxY - 1))
            path.addQuadCurve(to: CGPoint(x: rect.minX + 1, y: rect.maxY - 1),
                             control: CGPoint(x: rect.midX, y: rect.maxY - 4))
            path.closeSubpath()
        }
    }
}
