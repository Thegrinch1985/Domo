import SwiftUI
import LocalAuthentication
import AuthenticationServices

// MARK: - Login View

struct LoginView: View {
    
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var showSignUp = false
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
            backgroundView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    
                    logoSection
                        .padding(.bottom, 48)
                    
                    formSection
                        .padding(.horizontal, DomoTheme.screenPadding)
                        .padding(.bottom, 24)
                    
                    biometricSection
                        .padding(.bottom, 16)
                    
                    appleSignInSection
                        .padding(.bottom, 32)
                    
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
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(appState)
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Circle()
                .fill(.blue.opacity(0.08))
                .frame(width: 340, height: 340)
                .blur(radius: 100)
                .offset(x: -100, y: -220)
            
            Circle()
                .fill(.indigo.opacity(0.06))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 140, y: -30)
            
            Circle()
                .fill(.purple.opacity(0.05))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: -60, y: 320)
        }
    }
    
    // MARK: - Logo
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
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
                
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(DomoTheme.brandGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.3), radius: 24, y: 10)
                    
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
        VStack(spacing: 18) {
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .frame(width: 20)
                    
                    TextField("your@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(16)
                .background(DomoTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
            }
            
            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
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
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(16)
                .background(DomoTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
            }
            
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
        Group {
            if AuthService.biometricType != .none && AuthService.hasPreviousSession {
                VStack(spacing: 20) {
                    dividerRow
                    
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: AuthService.biometricType.icon)
                                .font(.system(size: 22))
                            Text("Sign in with \(AuthService.biometricType.label)")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(DomoTheme.cardBackground)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
                    }
                    .padding(.horizontal, DomoTheme.screenPadding)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            }
        }
    }
    
    // MARK: - Sign in with Apple
    
    private var appleSignInSection: some View {
        VStack(spacing: 20) {
            if AuthService.biometricType == .none || !AuthService.hasPreviousSession {
                dividerRow
            }
            
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result: result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
            .padding(.horizontal, 24)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    private var dividerRow: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5)
            Text("or")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Sign Up") { showSignUp = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
            }
        }
        .opacity(animateContent ? 1 : 0)
    }
    
    // MARK: - Actions
    
    private func signIn() {
        withAnimation { isLoading = true }
        
        do {
            let user = try AuthService.signIn(
                email: email,
                password: password,
                context: modelContext
            )
            appState.setUser(user)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        withAnimation { isLoading = false }
    }
    
    private func authenticateWithBiometrics() {
        withAnimation { isLoading = true }
        
        Task {
            do {
                let user = try await AuthService.signInWithBiometrics(context: modelContext)
                appState.setUser(user)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            withAnimation { isLoading = false }
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        do {
            let user = try AuthService.handleAppleSignIn(result: result, context: modelContext)
            appState.setUser(user)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSecure = true
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(DomoTheme.brandGradient)
                                .frame(width: 64, height: 64)
                                .shadow(color: .blue.opacity(0.3), radius: 16, y: 6)
                            
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 16)
                        
                        Text("Create Account")
                            .font(.title2.weight(.bold))
                        
                        Text("Set up your Domo account to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Form
                    VStack(spacing: 16) {
                        formField(
                            label: "Full Name",
                            icon: "person.fill",
                            placeholder: "John Doe",
                            text: $fullName,
                            contentType: .name,
                            capitalize: .words
                        )
                        
                        formField(
                            label: "Email",
                            icon: "envelope.fill",
                            placeholder: "your@email.com",
                            text: $email,
                            contentType: .emailAddress,
                            keyboard: .emailAddress
                        )
                        
                        // Password
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
                                    SecureField("At least 6 characters", text: $password)
                                        .textContentType(.newPassword)
                                } else {
                                    TextField("At least 6 characters", text: $password)
                                        .textContentType(.newPassword)
                                }
                                
                                Button { isSecure.toggle() } label: {
                                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(16)
                            .background(DomoTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.badge.checkmark")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                
                                SecureField("Re-enter your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                            .padding(16)
                            .background(DomoTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
                        }
                        
                        // Password strength indicator
                        if !password.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(0..<4) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(i < passwordStrength ? strengthColor : Color(.systemGray5))
                                        .frame(height: 4)
                                }
                                Text(strengthLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, DomoTheme.screenPadding)
                    
                    // Create Account Button
                    Button {
                        createAccount()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Create Account")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(formIsValid ? DomoTheme.brandGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: formIsValid ? .blue.opacity(0.25) : .clear, radius: 16, y: 8)
                    }
                    .disabled(!formIsValid || isLoading)
                    .padding(.horizontal, DomoTheme.screenPadding)
                    
                    // Apple Sign Up
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(Color(.separator).opacity(0.3))
                                .frame(height: 0.5)
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Rectangle()
                                .fill(Color(.separator).opacity(0.3))
                                .frame(height: 0.5)
                        }
                        .padding(.horizontal, 24)
                        
                        SignInWithAppleButton(.signUp) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAppleSignUp(result: result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Registration Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Helpers
    
    private func formField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType = .default,
        capitalize: TextInputAutocapitalization = .never
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                
                TextField(placeholder, text: text)
                    .textContentType(contentType)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(capitalize)
            }
            .padding(16)
            .background(DomoTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
        }
    }
    
    private var formIsValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private var passwordStrength: Int {
        var s = 0
        if password.count >= 6 { s += 1 }
        if password.count >= 10 { s += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { s += 1 }
        if password.range(of: "[0-9!@#$%^&*]", options: .regularExpression) != nil { s += 1 }
        return s
    }
    
    private var strengthColor: Color {
        switch passwordStrength {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .green
        }
    }
    
    private var strengthLabel: String {
        switch passwordStrength {
        case 1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        default: return "Strong"
        }
    }
    
    // MARK: - Actions
    
    private func createAccount() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            let user = try AuthService.register(
                fullName: fullName,
                email: email,
                password: password,
                context: modelContext
            )
            appState.setUser(user)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    private func handleAppleSignUp(result: Result<ASAuthorization, Error>) {
        do {
            let user = try AuthService.handleAppleSignIn(result: result, context: modelContext)
            appState.setUser(user)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
