import SwiftUI

@main
struct OddlyApp: App {
    @StateObject private var model: CalculatorViewModel

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting-reset"),
           let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        #endif
        _model = StateObject(wrappedValue: CalculatorViewModel())
    }

    var body: some Scene {
        WindowGroup {
            CalculatorView(model: model)
                .preferredColorScheme(model.appearance.colorScheme)
                .modifier(UITestTypeSize())
        }
        #if os(macOS)
        .defaultSize(width: 430, height: 830)
        .windowResizability(.contentMinSize)
        #endif
    }
}

private struct UITestTypeSize: ViewModifier {
    func body(content: Content) -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting-largest-type") {
            content.dynamicTypeSize(.accessibility5)
        } else if ProcessInfo.processInfo.arguments.contains("--uitesting-large-type") {
            content.dynamicTypeSize(.accessibility3)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
