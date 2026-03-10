import Foundation
import Security
import LocalAuthentication
import AuthenticationServices
import SwiftData
import CommonCrypto

// MARK: - Auth Service (stateless — state lives in AppState)

enum AuthService {
    
    private static let keychainService = "com.domo.auth"
    
    // MARK: - Registration
    
    static func register(
        fullName: String,
        email: String,
        password: String,
        context: ModelContext
    ) throws -> UserAccount {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidName
        }
        guard isValidEmail(normalizedEmail) else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        // Check if account already exists
        let descriptor = FetchDescriptor<UserAccount>(
            predicate: #Predicate { $0.email == normalizedEmail }
        )
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            throw AuthError.accountExists
        }
        
        let hashedPassword = hashPassword(password)
        try saveToKeychain(email: normalizedEmail, password: hashedPassword)
        
        let account = UserAccount(
            fullName: fullName.trimmingCharacters(in: .whitespaces),
            email: normalizedEmail
        )
        context.insert(account)
        try context.save()
        
        UserDefaults.standard.set(normalizedEmail, forKey: "lastLoggedInEmail")
        return account
    }
    
    // MARK: - Email / Password Login
    
    static func signIn(
        email: String,
        password: String,
        context: ModelContext
    ) throws -> UserAccount {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            throw AuthError.emptyFields
        }
        
        guard let storedHash = retrieveFromKeychain(email: normalizedEmail) else {
            throw AuthError.invalidCredentials
        }
        
        let inputHash = hashPassword(password)
        guard inputHash == storedHash else {
            throw AuthError.invalidCredentials
        }
        
        let descriptor = FetchDescriptor<UserAccount>(
            predicate: #Predicate { $0.email == normalizedEmail }
        )
        guard let account = try context.fetch(descriptor).first else {
            throw AuthError.invalidCredentials
        }
        
        UserDefaults.standard.set(normalizedEmail, forKey: "lastLoggedInEmail")
        return account
    }
    
    // MARK: - Sign in with Apple
    
    static func handleAppleSignIn(
        result: Result<ASAuthorization, Error>,
        context: ModelContext
    ) throws -> UserAccount {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.appleSignInFailed
            }
            
            let appleUserID = credential.user
            
            let descriptor = FetchDescriptor<UserAccount>(
                predicate: #Predicate { $0.appleUserID == appleUserID }
            )
            
            if let existing = try context.fetch(descriptor).first {
                UserDefaults.standard.set(existing.email, forKey: "lastLoggedInEmail")
                return existing
            } else {
                let fullName: String
                if let givenName = credential.fullName?.givenName {
                    let familyName = credential.fullName?.familyName ?? ""
                    fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
                } else {
                    fullName = "Apple User"
                }
                
                let email = credential.email ?? "\(appleUserID)@privaterelay.appleid.com"
                
                let account = UserAccount(
                    fullName: fullName,
                    email: email,
                    appleUserID: appleUserID
                )
                context.insert(account)
                try context.save()
                
                UserDefaults.standard.set(email, forKey: "lastLoggedInEmail")
                return account
            }
            
        case .failure(let error):
            throw AuthError.appleSignInError(error.localizedDescription)
        }
    }
    
    // MARK: - Biometric Login
    
    static func signInWithBiometrics(context: ModelContext) async throws -> UserAccount {
        let laContext = LAContext()
        var error: NSError?
        
        guard laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricUnavailable
        }
        
        guard let lastEmail = UserDefaults.standard.string(forKey: "lastLoggedInEmail") else {
            throw AuthError.noPreviousSession
        }
        
        let success = try await laContext.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Sign in to Domo"
        )
        
        guard success else {
            throw AuthError.biometricFailed
        }
        
        let descriptor = FetchDescriptor<UserAccount>(
            predicate: #Predicate { $0.email == lastEmail }
        )
        guard let account = try context.fetch(descriptor).first else {
            throw AuthError.invalidCredentials
        }
        
        return account
    }
    
    // MARK: - Biometric Availability
    
    static var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID:    return .faceID
        case .touchID:   return .touchID
        case .opticID:   return .opticID
        default:         return .none
        }
    }
    
    static var hasPreviousSession: Bool {
        UserDefaults.standard.string(forKey: "lastLoggedInEmail") != nil
    }
    
    enum BiometricType: Sendable {
        case none, faceID, touchID, opticID
        
        var label: String {
            switch self {
            case .faceID:  return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .none:    return "Biometrics"
            }
        }
        
        var icon: String {
            switch self {
            case .faceID:  return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "opticid"
            case .none:    return "lock.fill"
            }
        }
    }
    
    // MARK: - Keychain Helpers
    
    private static func saveToKeychain(email: String, password: String) throws {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: email
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: email,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError
        }
    }
    
    nonisolated private static func retrieveFromKeychain(email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    nonisolated private static func hashPassword(_ password: String) -> String {
        let salt = "domo_salt_v1"
        let salted = "\(salt)\(password)"
        let data = Data(salted.utf8)
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    nonisolated private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidName
    case invalidEmail
    case weakPassword
    case accountExists
    case emptyFields
    case invalidCredentials
    case keychainError
    case biometricUnavailable
    case biometricFailed
    case noPreviousSession
    case appleSignInFailed
    case appleSignInError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName:           return "Please enter your name."
        case .invalidEmail:          return "Please enter a valid email address."
        case .weakPassword:          return "Password must be at least 6 characters."
        case .accountExists:         return "An account with this email already exists."
        case .emptyFields:           return "Please fill in all fields."
        case .invalidCredentials:    return "Invalid email or password."
        case .keychainError:         return "Failed to save credentials securely."
        case .biometricUnavailable:  return "Biometric authentication is not available."
        case .biometricFailed:       return "Biometric authentication failed."
        case .noPreviousSession:     return "No previous session found. Please sign in."
        case .appleSignInFailed:     return "Sign in with Apple failed."
        case .appleSignInError(let msg): return "Apple Sign In: \(msg)"
        }
    }
}
