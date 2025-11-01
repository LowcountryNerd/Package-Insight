import Foundation
import Supabase
import Combine
// MARK: - User Roles
enum UserRole: String, CaseIterable {
    case admin = "admin"
    case user = "user"
    var displayName: String {
        switch self {
        case .admin:
            return "Administrator"
        case .user:
            return "User"
        }
    }
}
// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case insufficientPermissions
    var errorDescription: String? {
        switch self {
        case .insufficientPermissions:
            return "Insufficient permissions. Admin access required."
        }
    }
}
// MARK: - Authentication Manager
class AuthManager: ObservableObject {
       @Published var isAuthenticated = false
       @Published var currentUser: User?
       @Published var isLoading = false
       @Published var errorMessage: String?
       @Published var isAdmin = false
    @Published var userRole: UserRole = .user
    private var cancellables = Set<AnyCancellable>()
    init() {
        setupAuthStateListener()
    }
    // MARK: - Authentication State Listener
    private func setupAuthStateListener() {
        Task {
               for await state in supabase.auth.authStateChanges {
                   await MainActor.run {
                       if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                           self.isAuthenticated = state.session != nil
                           self.currentUser = state.session?.user
                           self.updateAdminStatus(user: state.session?.user)
                       }
                   }
               }
        }
    }
    // MARK: - Sign Up
    func signUp(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        // Retry logic for TLS errors
        var attempt = 0
        let maxAttempts = 3
        while attempt < maxAttempts {
            do {
                let response = try await supabase.auth.signUp(
                    email: email,
                    password: password
                )
                await MainActor.run {
                    self.currentUser = response.user
                    self.isAuthenticated = response.user != nil
                    self.isLoading = false
                    if response.user == nil {
                        self.errorMessage = "Please check your email for verification link"
                    }
                }
                return // Success, exit retry loop
            } catch {
                attempt += 1
                let errorMessage = self.getUserFriendlyErrorMessage(from: error)
                // Check if it's a TLS error and we can retry
                let errorString = error.localizedDescription.lowercased()
                let isTLS = errorString.contains("tls") || errorString.contains("ssl") || errorString.contains("-9816")
                if isTLS && attempt < maxAttempts {
                    // Wait before retrying for TLS errors
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 2) * 1_000_000_000) // 2, 4 seconds
                    continue
                } else {
                    // Final attempt failed or non-TLS error
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = errorMessage
                    }
                    return
                }
            }
        }
    }
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        // Retry logic for TLS errors
        var attempt = 0
        let maxAttempts = 3
        while attempt < maxAttempts {
            do {
                let response = try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
                await MainActor.run {
                    self.currentUser = response.user
                    self.isAuthenticated = response.user != nil
                    self.isLoading = false
                }
                return // Success, exit retry loop
            } catch {
                attempt += 1
                let errorMessage = self.getUserFriendlyErrorMessage(from: error)
                // Check if it's a TLS error and we can retry
                let errorString = error.localizedDescription.lowercased()
                let isTLS = errorString.contains("tls") || errorString.contains("ssl") || errorString.contains("-9816")
                if isTLS && attempt < maxAttempts {
                    // Wait before retrying for TLS errors
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 2) * 1_000_000_000) // 2, 4 seconds
                    continue
                } else {
                    // Final attempt failed or non-TLS error
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = errorMessage
                    }
                    return
                }
            }
        }
    }
    // MARK: - Sign In with Magic Link
    func signInWithMagicLink(email: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: "packageinsight://login-callback")
            )
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Check your inbox for the magic link."
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    // MARK: - Sign Out
    func signOut() async {
        await MainActor.run {
            isLoading = true
        }
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false
                self.errorMessage = nil
                self.isAdmin = false // Reset admin status on sign out
                self.userRole = .user // Reset user role on sign out
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    // MARK: - Password Reset
    func resetPassword(email: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Password reset email sent. Check your inbox."
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    // MARK: - Handle Deep Link
    func handleDeepLink(_ url: URL) async {
        do {
            try await supabase.auth.session(from: url)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    // MARK: - Clear Error
    func clearError() {
        errorMessage = nil
    }
    // MARK: - Error Handling
    private func getUserFriendlyErrorMessage(from error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
               // TLS/Network errors
               if errorString.contains("tls") || errorString.contains("ssl") || errorString.contains("certificate") || errorString.contains("-9816") {
                   return "SSL connection failed. This is a known issue with some Supabase projects behind Cloudflare. Please contact your administrator or try a different network."
               }
        // Authentication errors
        if errorString.contains("invalid") && errorString.contains("credentials") {
            return "Invalid email or password. Please try again."
        }
        if errorString.contains("user not found") {
            return "No account found with this email address."
        }
        if errorString.contains("email not confirmed") {
            return "Please check your email and click the verification link before signing in."
        }
        if errorString.contains("too many requests") {
            return "Too many login attempts. Please wait a few minutes and try again."
        }
        // Generic error fallback
        return "An error occurred. Please try again."
    }
           // MARK: - Check Authentication Status
           func checkAuthStatus() {
               Task {
                   do {
                       let session = try await supabase.auth.session
                       await MainActor.run {
                           self.isAuthenticated = session.user != nil
                           self.currentUser = session.user
                           self.updateAdminStatus(user: session.user)
                       }
                   } catch {
                       await MainActor.run {
                           self.isAuthenticated = false
                           self.currentUser = nil
                           self.isAdmin = false
                       }
                   }
               }
           }
    // MARK: - Role Management
    private func updateAdminStatus(user: User?) {
        guard let user = user else {
            isAdmin = false
            userRole = .user
            return
        }
        // Check if user has admin role in app_metadata
        // For now, we'll set admin status based on email for testing
        // In production, this should check the actual app_metadata
        if let email = user.email, email == "test@packageinsight.com" {
            isAdmin = true
            userRole = .admin
        } else {
            isAdmin = false
            userRole = .user
        }
    }
           // MARK: - User Management (Admin Only)
           // Note: Admin user management requires service role key and server-side implementation
           // These methods are placeholders for when you implement server-side admin APIs
           func createUser(email: String, password: String, isAdmin: Bool = false) async throws -> User {
               guard isAdmin else {
                   throw AuthError.insufficientPermissions
               }
               // TODO: Implement server-side user creation API
               // This would require a backend service with service role key
               throw AuthError.insufficientPermissions
           }
           func updateUserRole(userId: String, isAdmin: Bool) async throws {
               guard self.isAdmin else {
                   throw AuthError.insufficientPermissions
               }
               // TODO: Implement server-side user role update API
               // This would require a backend service with service role key
               throw AuthError.insufficientPermissions
           }
           func deleteUser(userId: String) async throws {
               guard isAdmin else {
                   throw AuthError.insufficientPermissions
               }
               // TODO: Implement server-side user deletion API
               // This would require a backend service with service role key
               throw AuthError.insufficientPermissions
           }
           func listUsers() async throws -> [User] {
               guard isAdmin else {
                   throw AuthError.insufficientPermissions
               }
               // TODO: Implement server-side user listing API
               // This would require a backend service with service role key
               throw AuthError.insufficientPermissions
           }
    // MARK: - Test Connection
    func testConnection() async {
        print(" Testing Supabase connection...")
        do {
            // Simple test to check if we can reach Supabase
            let _ = try await supabase.auth.session
            print(" Supabase connection successful!")
        } catch {
            print(" Supabase connection failed: \(error)")
            print(" Error details: \(error.localizedDescription)")
            // Check for specific error types
            if let urlError = error as? URLError {
                print(" URL Error code: \(urlError.code.rawValue)")
                print(" URL Error description: \(urlError.localizedDescription)")
                // Check if it's the specific SSL error we're seeing
                if urlError.code.rawValue == -9816 {
                    print(" Detected SSL error -9816")
                    print(" This is a known iOS SSL issue with Supabase")
                    print(" Trying alternative connection method...")
                    await testAlternativeConnection()
                }
            }
        }
    }
    // MARK: - Alternative Connection Test
    private func testAlternativeConnection() async {
        print(" Testing alternative connection method...")
        // Try a simple HTTP request to test basic connectivity
        guard let url = URL(string: "https://savkvcxocobpwsyzrpcj.supabase.co/rest/v1/") else {
            print(" Invalid Supabase URL")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("sb_publishable_8yhrOhHpy7VHm-P4GkbjWg_z0rScLAf", forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print(" Alternative connection successful! Status: \(httpResponse.statusCode)")
            }
        } catch {
            print(" Alternative connection also failed: \(error)")
            // If both methods fail, provide specific guidance
            await MainActor.run {
                self.errorMessage = "SSL connection failed. This is a known issue with some Supabase projects. Please contact your administrator or try a different network."
            }
        }
    }
}