import SwiftUI
struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var password = ""
    @State private var showingPasswordReset = false
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                headerView
                // Login Form
                loginFormView
                // Actions
                actionsView
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView()
        }
    }
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Package Insight")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Professional Package Risk Assessment")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    // MARK: - Login Form View
    private var loginFormView: some View {
        VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.primary)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(.primary)
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            // Error Message
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            // Login Button
            Button(action: login) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isFormValid || authManager.isLoading)
        }
    }
           // MARK: - Actions View
           private var actionsView: some View {
               VStack(spacing: 16) {
                   // Forgot Password
                   Button("Forgot Password?") {
                       showingPasswordReset = true
                   }
                   .font(.subheadline)
                   .foregroundColor(.blue)
                   // Admin Notice
                   Text("New users can only be created by administrators")
                       .font(.caption)
                       .foregroundColor(.secondary)
                       .multilineTextAlignment(.center)
                       .padding(.top, 8)
               }
           }
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    // MARK: - Actions
    private func login() {
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}
#Preview {
    LoginView()
}