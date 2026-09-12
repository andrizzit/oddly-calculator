import SwiftUI
import CalculatorCore

enum CalculatorSheet: String, Identifiable {
    case history, settings, collection
    var id: String { rawValue }
}

struct CalculatorView: View {
    @ObservedObject var model: CalculatorViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheet: CalculatorSheet?
    @ScaledMetric(relativeTo: .title) private var keyFont: CGFloat = 30

    private var palette: OddlyPalette { OddlyPalette(dark: colorScheme == .dark) }
    private var companionHeight: CGFloat? {
        if typeSize.isAccessibilitySize { return nil }
        if typeSize >= .xxxLarge { return 132 }
        if typeSize >= .xxLarge { return 116 }
        if typeSize >= .xLarge { return 104 }
        return 88
    }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 700 && geometry.size.width > geometry.size.height
            let keyHeight = max(typeSize.isAccessibilitySize ? 74 : 52,
                                min(88, (geometry.size.height - (model.showScience ? 570 : 508)
                                         - ((companionHeight ?? 88) - 88)) / 5))
            ScrollView {
                VStack(spacing: 10) {
                    header
                    if wide {
                        HStack(alignment: .center, spacing: 34) {
                            VStack(spacing: 22) {
                                display(minimumHeight: 160)
                                companion
                                if model.showScience { scienceKeys(height: 58) }
                                collectionLink
                            }
                            .frame(maxWidth: .infinity)
                            keypad(height: max(54, min(86, (geometry.size.height - 145) / 5)))
                                .frame(maxWidth: 460)
                        }
                    } else {
                        display(minimumHeight: typeSize.isAccessibilitySize ? 124 : 96)
                        companion
                        if model.showScience { scienceKeys(height: 52) }
                        keypad(height: keyHeight)
                        collectionLink
                    }
                }
                .padding(.horizontal, wide ? 32 : 22)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: wide ? 1040 : 510)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height,
                       alignment: geometry.size.width > 700 ? .center : .top)
            }
            .scrollIndicators(.hidden)
            .background(palette.background)
        }
        .background(palette.background)
        .foregroundStyle(palette.ink)
        .tint(palette.ink)
        .sheet(item: $sheet) { destination in
            switch destination {
            case .history: HistoryView(model: model)
            case .settings: SettingsView(model: model)
            case .collection: CollectionView(model: model)
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 620)
        #endif
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("Oddly")
                    .font(.system(size: 35, weight: .heavy, design: .rounded))
                    .kerning(-1.8)
                Text(".")
                    .font(.system(size: 35, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.orange)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Oddly calculator")
            Spacer()
            RoundToolbarButton(symbol: "function", label: "More math", id: "mode.science", palette: palette) {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    model.showScience.toggle()
                }
            }
            .accessibilityValue(model.showScience ? "Expanded" : "Collapsed")
            .accessibilityHint("Shows square, square root, reciprocal, and pi")
            RoundToolbarButton(symbol: "clock.arrow.circlepath", label: "History", id: "toolbar.history", palette: palette) {
                sheet = .history
            }
            RoundToolbarButton(symbol: "slider.horizontal.3", label: "Settings", id: "toolbar.settings", palette: palette) {
                sheet = .settings
            }
        }
        .frame(minHeight: 48)
    }

    private func display(minimumHeight: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            HStack(alignment: .center, spacing: 8) {
                Text(model.engine.expression.isEmpty ? "LET’S FIGURE IT OUT" : model.engine.expression)
                    .font(model.engine.expression.isEmpty
                          ? .system(size: 11, weight: .semibold, design: .monospaced)
                          : .system(.callout, design: .monospaced))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel("Expression")
                    .accessibilityValue(model.engine.expression.isEmpty ? "No pending operation" : model.engine.expression)
                    .accessibilityIdentifier("calculator.expression")
                FeedbackButton(pressedFill: palette.mint, foreground: palette.ink) {
                    model.press(.delete)
                } label: {
                    Image(systemName: "delete.left")
                        .font(.system(size: 19, weight: .regular))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Delete last digit")
                .accessibilityHint("Cancels a pending operator, or clears a completed result")
                .accessibilityIdentifier("key.delete")
                .keyboardShortcut(.delete, modifiers: [])
            }
            Text(model.formattedDisplay)
                .font(.system(size: 60, weight: .light, design: .rounded).monospacedDigit())
                .tracking(-2)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .contentShape(Rectangle())
                .contextMenu {
                    Button("Copy result", systemImage: "doc.on.doc") { model.copyResult() }
                        .disabled(model.engine.error != nil)
                }
                .accessibilityLabel("Result")
                .accessibilityValue(model.engine.display)
                .accessibilityIdentifier("calculator.display")
                .accessibilityAction(named: "Copy result") { model.copyResult() }
        }
        .frame(minHeight: minimumHeight, alignment: .bottom)
    }

    private var companion: some View {
        HStack(spacing: 12) {
            if model.engine.error != nil {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 27, weight: .regular))
                    .frame(width: 44)
                    .accessibilityHidden(true)
            } else if model.personality == .calm {
                Image(systemName: "leaf")
                    .font(.system(size: 25, weight: .regular))
                    .frame(width: 44)
                    .accessibilityHidden(true)
            } else {
                OddlyMascot(celebrating: model.celebrationCount.isMultiple(of: 2) == false)
                    .overlay {
                        DiscoveryCelebration(trigger: model.celebrationCount, mode: model.personality)
                    }
            }
            VStack(alignment: .leading, spacing: 3) {
                if let egg = model.reaction?.egg, model.engine.error == nil, model.notice == nil {
                    Text("DISCOVERED · \(egg.title.uppercased())")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(0.7)
                }
                Text(model.companionMessage)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("companion.message")
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .frame(height: companionHeight, alignment: .leading)
        .frame(minHeight: typeSize.isAccessibilitySize ? 88 : nil, alignment: .leading)
        .background(model.engine.error == nil ? palette.mint : palette.utility,
                    in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.celebrationCount)
    }

    private func keypad(height: CGFloat) -> some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                key("AC", .clear, "All clear", "clear", height: height, utility: true, shortcut: .escape)
                key("+/−", .toggleSign, "Change sign", "sign", height: height, utility: true)
                key("%", .percent, "Percent", "percent", height: height, utility: true, shortcut: "%")
                operationKey(.divide, id: "divide", height: height, shortcut: "/")
            }
            GridRow {
                digit(7, height: height); digit(8, height: height); digit(9, height: height)
                operationKey(.multiply, id: "multiply", height: height, shortcut: "*")
            }
            GridRow {
                digit(4, height: height); digit(5, height: height); digit(6, height: height)
                operationKey(.subtract, id: "subtract", height: height, shortcut: "-")
            }
            GridRow {
                digit(1, height: height); digit(2, height: height); digit(3, height: height)
                operationKey(.add, id: "add", height: height, shortcut: "+")
            }
            GridRow {
                digit(0, height: height).gridCellColumns(2)
                key(".", .decimal, "Decimal point", "decimal", height: height, shortcut: ".")
                key("=", .equals, "Equals", "equals", height: height, accent: true, shortcut: .return)
            }
        }
    }

    private func scienceKeys(height: CGFloat) -> some View {
        HStack(spacing: 10) {
            key("x²", .unary(.square), "Square", "square", height: height, utility: true, small: true)
            key("√x", .unary(.squareRoot), "Square root", "squareRoot", height: height, utility: true, small: true)
            key("1/x", .unary(.reciprocal), "Reciprocal", "reciprocal", height: height, utility: true, small: true)
            key("π", .pi, "Pi", "pi", height: height, utility: true, small: true)
        }
    }

    private func digit(_ number: Int, height: CGFloat) -> some View {
        key(String(number), .digit(number), String(number), String(number), height: height,
            shortcut: KeyEquivalent(Character(String(number))))
    }

    private func operationKey(_ operation: CalculatorOperator, id: String, height: CGFloat, shortcut: KeyEquivalent) -> some View {
        key(operation.rawValue, .operation(operation), operation.accessibilityName, id,
            height: height, accent: true, selected: model.engine.pendingOperation == operation, shortcut: shortcut)
    }

    private func key(_ title: String, _ action: CalculatorKey, _ label: String, _ id: String,
                     height: CGFloat, utility: Bool = false, accent: Bool = false,
                     selected: Bool = false, shortcut: KeyEquivalent? = nil, small: Bool = false) -> some View {
        let fill = accent ? palette.orange : (utility ? palette.utility : palette.digit)
        let pressedFill = accent ? palette.pressedOrange : (utility ? palette.pressedUtility : palette.pressedDigit)
        let foreground = accent ? palette.orangeInk : palette.ink
        let button = FeedbackButton(fill: fill, pressedFill: pressedFill, foreground: foreground,
                                    selected: selected, cornerRadius: 21, raised: true, bordered: true) {
            model.press(action)
        } label: {
            Text(title)
                .font(.system(size: small ? min(keyFont, 22) : min(keyFont, 42),
                              weight: accent ? .medium : .regular, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .contentShape(RoundedRectangle(cornerRadius: 21))
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier("key.\(id)")
        .accessibilityAddTraits(selected ? .isSelected : [])
        return Group {
            if let shortcut { button.keyboardShortcut(shortcut, modifiers: []) }
            else { button }
        }
    }

    private var collectionLink: some View {
        FeedbackButton(pressedFill: palette.mint, foreground: palette.ink) {
            sheet = .collection
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                Text("Curiosity cabinet")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(model.discoveredEggIDs.count) / \(PersonalityEngine.catalogue.count)")
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .font(.system(.footnote, design: .rounded))
            .foregroundStyle(palette.secondary)
            .frame(minHeight: 44)
            .padding(.horizontal, 3)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Curiosity cabinet, \(model.discoveredEggIDs.count) of \(PersonalityEngine.catalogue.count) discoveries")
        .accessibilityIdentifier("toolbar.collection")
    }
}
