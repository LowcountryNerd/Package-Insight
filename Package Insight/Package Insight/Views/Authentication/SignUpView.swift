import SwiftUI
struct SignUpView: View {
    @StateObject private var authManager = AuthManager()
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var company = ""
    @State private var agreeToTerms = false
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    // Sign Up Form
                    signUpFormView
                    // Terms and Conditions
                    termsView
                    // Sign Up Button
                    signUpButton
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Join Package Insight")
                .font(.title2)
                .fontWeight(.bold)
            Text("Create your professional account to start scanning and analyzing packages")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    // MARK: - Sign Up Form View
    private var signUpFormView: some View {
        VStack(spacing: 20) {
            // Full Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.headline)
                    .foregroundColor(.primary)
                TextField("Enter your full name", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            // Company Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Company (Optional)")
                    .font(.headline)
                    .foregroundColor(.primary)
                TextField("Enter your company name", text: $company)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
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
                SecureField("Create a password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            // Error Message
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
    }
    // MARK: - Terms View
    private var termsView: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { agreeToTerms.toggle() }) {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreeToTerms ? .blue : .gray)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("I agree to the Terms of Service and Privacy Policy")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                HStack {
                    Button("Terms of Service") {
                        // TODO: Show terms of service
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    Text("and")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Privacy Policy") {
                        // TODO: Show privacy policy
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            Spacer()
        }
    }
    // MARK: - Sign Up Button
    private var signUpButton: some View {
        Button(action: signUp) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Create Account")
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
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !fullName.isEmpty &&
               !email.isEmpty &&
               !password.isEmpty &&
               email.contains("@") &&
               agreeToTerms
    }
    // MARK: - Actions
    private func signUp() {
        Task {
            await authManager.signUp(email: email, password: password)
            // If sign up successful, dismiss the view
            if authManager.isAuthenticated {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}
#Preview {
    SignUpView()
}