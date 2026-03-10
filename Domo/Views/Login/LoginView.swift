import SwiftUI
import LocalAuthentication

struct LoginView: View {
    
    @EnvironmentObject private var appState: AppState
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSecure = true
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateContent = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    
                    // Logo & Title
                    logoSection
                        .padding(.bottom, 48)
                    
                    // Login Form
                    formSection
                        .padding(.horizontal, DomoTheme.screenPadding)
                        .padding(.bottom, 24)
                    
                    // Biometric Button
                    biometricSection
                        .padding(.bottom, 32)
                    
                    // Footer
                    footerSection
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateContent = true
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Floating gradient orbs
            Circle()
                .fill(.blue.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(.indigo.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 120, y: -50)
            
            Circle()
                .fill(.purple.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -50, y: 300)
        }
    }
    
    // MARK: - Logo
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(DomoTheme.brandGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.4), radius: 20, y: 8)
                    
                    Image(systemName: "house.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            
            VStack(spacing: 6) {
                Text("Domo")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                
                Text("Your home, organized.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(logoOpacity)
        }
    }
    
    // MARK: - Form
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    TextField("your@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(16)
                .background(Color(.systemGray6).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    if isSecure {
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                    } else {
                        TextField("Enter your password", text: $password)
                            .textContentType(.password)
                    }
                    
                    Button {
                        isSecure.toggle()
                    } label: {
                        Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                )
            }
            
            // Forgot password
            HStack {
                Spacer()
                Button("Forgot password?") { }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
            }
            .padding(.top, 2)
            
            // Sign In Button
            Button {
                signIn()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Sign In")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(DomoTheme.brandGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)
            }
            .disabled(isLoading)
            .padding(.top, 8)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
    }
    
    // MARK: - Biometric
    
    private var biometricSection: some View {
        VStack(spacing: 20) {
            // Divider
            HStack(spacing: 16) {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
            }
            .padding(.horizontal, DomoTheme.screenPadding)
            
            // Biometric button
            Button {
                authenticateWithBiometrics()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: biometricIcon)
                        .font(.system(size: 22))
                    Text("Sign in with \(biometricName)")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.systemGray6).opacity(0.6))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(.horizontal, DomoTheme.screenPadding)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Sign Up") { signIn() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
            }
        }
        .opacity(animateContent ? 1 : 0)
    }
    
    // MARK: - Biometric Helpers
    
    private var biometricIcon: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }
    
    private var biometricName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Passcode"
        }
    }
    
    // MARK: - Actions
    
    private func signIn() {
        withAnimation(.easeInOut(duration: 0.2)) { isLoading = true }
        
        // Simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isLoading = false
                appState.isLoggedIn = true
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback: just sign in
            signIn()
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Sign in to Domo"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        appState.isLoggedIn = true
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
