import SwiftUI

extension Font {
    // Monospaced font variants for the entire app
    static func monospacedSystem(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .monospaced)
    }
    
    // Monospaced versions of standard text styles
    static let monospacedLargeTitle = Font.system(.largeTitle, design: .monospaced)
    static let monospacedTitle = Font.system(.title, design: .monospaced)
    static let monospacedTitle2 = Font.system(.title2, design: .monospaced)
    static let monospacedTitle3 = Font.system(.title3, design: .monospaced)
    static let monospacedHeadline = Font.system(.headline, design: .monospaced)
    static let monospacedSubheadline = Font.system(.subheadline, design: .monospaced)
    static let monospacedBody = Font.system(.body, design: .monospaced)
    static let monospacedCallout = Font.system(.callout, design: .monospaced)
    static let monospacedFootnote = Font.system(.footnote, design: .monospaced)
    static let monospacedCaption = Font.system(.caption, design: .monospaced)
    static let monospacedCaption2 = Font.system(.caption2, design: .monospaced)
}

// View modifier to apply monospaced fonts globally
struct MonospacedFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.monospacedBody)
    }
}

extension View {
    func monospacedFont() -> some View {
        self.modifier(MonospacedFontModifier())
    }
}
