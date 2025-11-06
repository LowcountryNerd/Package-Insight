import SwiftUI
import Supabase
import Auth

struct UserManagementView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var users: [Auth.User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateUser = false
    @State private var newUserEmail = ""
    @State private var newUserPassword = ""
    @State private var newUserIsAdmin = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(users) { user in
                            UserRowView(user: user, authManager: authManager, supabaseService: supabaseService) {
                                await loadUsers()
                            }
                        }
                    }
                    .refreshable {
                        await loadUsers()
                    }
                }
            }
            .navigationTitle("User Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add User") {
                        showingCreateUser = true
                    }
                    .disabled(!authManager.isAdmin)
                }
            }
            .alert("Create New User", isPresented: $showingCreateUser) {
                TextField("Email", text: $newUserEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Password", text: $newUserPassword)
                Toggle("Admin", isOn: $newUserIsAdmin)
                Button("Cancel", role: .cancel) {
                    resetForm()
                }
                Button("Create") {
                    Task {
                        await createUser()
                    }
                }
                .disabled(newUserEmail.isEmpty || newUserPassword.isEmpty)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .task {
            await loadUsers()
        }
    }
    
    private func loadUsers() async {
        guard authManager.isAdmin else { return }
        
        isLoading = true
        do {
            let fetchedUsers = try await supabaseService.fetchUsers()
            await MainActor.run {
                self.users = fetchedUsers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func createUser() async {
        isLoading = true
        do {
            let newUser = try await supabaseService.createUser(
                email: newUserEmail,
                password: newUserPassword,
                isAdmin: newUserIsAdmin
            )
            await MainActor.run {
                self.users.insert(newUser, at: 0)
                self.isLoading = false
                self.showingCreateUser = false
                self.resetForm()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.showingCreateUser = false
            }
        }
    }
    
    private func resetForm() {
        newUserEmail = ""
        newUserPassword = ""
        newUserIsAdmin = false
    }
}

struct UserRowView: View {
    let user: Auth.User
    @ObservedObject var authManager: AuthManager
    @ObservedObject var supabaseService: SupabaseService
    let onUpdate: () async -> Void
    
    @State private var showingDeleteAlert = false
    @State private var showingRoleAlert = false
    @State private var errorMessage: String?
    
    private var isAdmin: Bool {
        (user.appMetadata["role"] as? String) == "admin"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.email ?? "Unknown")
                        .font(.headline)
                    Text("ID: \(user.id.uuidString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isAdmin {
                    Label("Admin", systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                } else {
                    Label("User", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Created: \(DateFormatter.shortDate.string(from: user.createdAt))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if authManager.isAdmin && user.id != authManager.currentUser?.id {
                HStack(spacing: 12) {
                    Button(action: {
                        showingRoleAlert = true
                    }) {
                        Label(isAdmin ? "Remove Admin" : "Make Admin", systemImage: isAdmin ? "person.fill" : "crown.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .alert("Delete User", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteUser()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(user.email ?? "this user")? This action cannot be undone.")
        }
        .alert("Change Role", isPresented: $showingRoleAlert) {
            Button("Cancel", role: .cancel) { }
            Button(isAdmin ? "Remove Admin" : "Make Admin") {
                Task {
                    await updateRole()
                }
            }
        } message: {
            Text("Change \(user.email ?? "this user")'s role to \(isAdmin ? "regular user" : "admin")?")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteUser() async {
        do {
            try await supabaseService.deleteUser(userId: user.id)
            await onUpdate()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func updateRole() async {
        do {
            _ = try await supabaseService.updateUserRole(userId: user.id, isAdmin: !isAdmin)
            await onUpdate()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
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
