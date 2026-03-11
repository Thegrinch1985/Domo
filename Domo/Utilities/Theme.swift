import SwiftUI

// MARK: - Domo Design System

/// Centralized theme for consistent, professional styling throughout the app.
enum DomoTheme {
    
    // MARK: - Colors
    
    /// Primary brand gradient
    static let accentGradient = LinearGradient(
        colors: [Color("AccentStart", bundle: nil), Color("AccentEnd", bundle: nil)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Fallback accent gradient using system colors
    static let brandGradient = LinearGradient(
        colors: [.blue, .indigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [.orange, .pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [.green, .mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let elevatedBackground = Color(.tertiarySystemGroupedBackground)
    
    /// Adaptive border opacity – lighter in light mode, more visible in dark
    static func borderOpacity(for scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.06 : 0.10
    }
    
    // MARK: - Spacing
    
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 28
    static let itemSpacing: CGFloat = 12
    
    // MARK: - Corner Radius
    
    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 22
    static let radiusXL: CGFloat = 28
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = DomoTheme.radiusMedium
    var opacity: Double = 0.08
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.8))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.white.opacity(opacity))
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - Gradient Icon Background

struct GradientIcon: View {
    let icon: String
    let gradient: LinearGradient
    var size: CGFloat = 44
    var iconScale: CGFloat = 0.45
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(gradient)
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * iconScale, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = DomoTheme.radiusMedium) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
    
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
    
    /// Standard card styling used throughout the app
    func domoCard(padding: CGFloat = DomoTheme.cardPadding) -> some View {
        self
            .padding(padding)
            .background(DomoTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                    .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
            )
    }
    
    /// Animated entrance from bottom
    func slideUp(delay: Double = 0) -> some View {
        self
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: true)
    }
}

// MARK: - Animated Number

struct AnimatedNumber: View {
    let value: Double
    let format: FloatingPointFormatStyle<Double>.Currency
    
    @State private var animatedValue: Double = 0
    
    var body: some View {
        Text(animatedValue.formatted(format))
            .onAppear { withAnimation(.easeOut(duration: 0.8)) { animatedValue = value } }
            .onChange(of: value) { _, new in
                withAnimation(.easeOut(duration: 0.5)) { animatedValue = new }
            }
            .contentTransition(.numericText(value: animatedValue))
    }
}
