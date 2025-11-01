import SwiftUI
struct PasswordResetView: View {
    @StateObject private var authManager = AuthManager()
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isEmailSent = false
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                headerView
                if isEmailSent {
                    successView
                } else {
                    // Password Reset Form
                    resetFormView
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)
            .navigationTitle("Reset Password")
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
        VStack(spacing: 16) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text(isEmailSent ? "Check Your Email" : "Reset Your Password")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text(isEmailSent ?
                 "We've sent a password reset link to your email address. Please check your inbox and follow the instructions to reset your password." :
                 "Enter your email address and we'll send you a link to reset your password.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    // MARK: - Reset Form View
    private var resetFormView: some View {
        VStack(spacing: 24) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.headline)
                    .foregroundColor(.primary)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            // Error Message
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            // Send Reset Button
            Button(action: sendResetEmail) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Send Reset Link")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEmailValid ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isEmailValid || authManager.isLoading)
            // Back to Login
            Button("Back to Sign In") {
                dismiss()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
    }
    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            // Instructions
            VStack(spacing: 16) {
                Text("Reset Link Sent!")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("We've sent a password reset link to:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(email)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                Text("Please check your email and click the link to reset your password. The link will expire in 24 hours.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            // Action Buttons
            VStack(spacing: 12) {
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                Button("Send Another Email") {
                    isEmailSent = false
                    authManager.clearError()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
    }
    // MARK: - Computed Properties
    private var isEmailValid: Bool {
        return !email.isEmpty && email.contains("@")
    }
    // MARK: - Actions
    private func sendResetEmail() {
        Task {
            await authManager.resetPassword(email: email)
            if authManager.errorMessage == nil {
                await MainActor.run {
                    isEmailSent = true
                }
            }
        }
    }
}
#Preview {
    PasswordResetView()
}