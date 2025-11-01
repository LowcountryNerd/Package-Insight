import SwiftUI
import Supabase
import Auth
struct UserManagementView: View {
    @StateObject private var authManager = AuthManager()
    @State private var users: [Auth.User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateUser = false
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Admin Notice
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    Text("Admin Panel")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("User management features require server-side implementation with service role key")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                // Current User Info
                if let currentUser = authManager.currentUser {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current User")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email: \(currentUser.email ?? "Unknown")")
                                .font(.subheadline)
                            Text("Role: \(authManager.userRole.displayName)")
                                .font(.subheadline)
                                .foregroundColor(authManager.userRole == .admin ? .blue : .secondary)
                            Text("Created: \(DateFormatter.shortDate.string(from: currentUser.createdAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                Spacer()
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("To enable user management:")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Create server-side admin API endpoints")
                        Text("2. Use Supabase service role key (not publishable key)")
                        Text("3. Implement user CRUD operations")
                        Text("4. Update AuthManager methods")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("User Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
#Preview {
    UserManagementView()
}