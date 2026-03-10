import SwiftUI

struct AppearanceSettingsView: View {
    
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            // Preview card
            Section {
                appearancePreview
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            
            // Mode picker
            Section("Theme") {
                ForEach(AppState.AppearanceMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.appearanceMode = mode
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(mode == appState.appearanceMode ? .blue : .secondary)
                                .frame(width: 28)
                            
                            Text(mode.label)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if mode == appState.appearanceMode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.blue)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section {
                Text("**System** follows your device settings.\nSwitch manually if you prefer a specific look.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Preview Card
    
    private var appearancePreview: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                previewTile(.light, label: "Light")
                previewTile(.dark, label: "Dark")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
    }
    
    private func previewTile(_ scheme: ColorScheme, label: String) -> some View {
        let isActive: Bool = {
            switch appState.appearanceMode {
            case .system: return colorScheme == scheme
            case .light:  return scheme == .light
            case .dark:   return scheme == .dark
            }
        }()
        
        return VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 14)
                .fill(scheme == .dark ? Color.black : Color.white)
                .frame(height: 100)
                .overlay(
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(scheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .frame(height: 14)
                            .padding(.horizontal, 14)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(scheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .frame(width: 80, height: 14)
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.blue.gradient)
                                .frame(width: 20, height: 20)
                            Circle()
                                .fill(.indigo.gradient)
                                .frame(width: 20, height: 20)
                            Circle()
                                .fill(.purple.gradient)
                                .frame(width: 20, height: 20)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isActive ? .blue : .clear, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            
            Text(label)
                .font(.caption.weight(isActive ? .bold : .medium))
                .foregroundStyle(isActive ? .blue : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
    .environmentObject(AppState())
}
