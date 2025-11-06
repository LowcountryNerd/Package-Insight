import SwiftUI
import Supabase
import Auth

struct VAISafeAccountsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var authManager = AuthManager()
    @State private var safeAccounts: [VAISafeAccount] = []
    @State private var isLoading = false
    @State private var showingAddAccount = false
    @State private var newAccountNumber = ""
    @State private var newNotes = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading safe accounts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(safeAccounts) { account in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Account: \(account.accountNumber)")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                                if let notes = account.notes, !notes.isEmpty {
                                    Text("Notes: \(notes)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text("Added: \(DateFormatter.shortDate.string(from: account.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteAccount)
                    }
                    .refreshable {
                        await loadSafeAccounts()
                    }
                }
            }
            .navigationTitle("VAI Safe Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddAccount = true
                    }
                }
            }
            .alert("Add Safe Account", isPresented: $showingAddAccount) {
                TextField("Account Number", text: $newAccountNumber)
                TextField("Notes (Optional)", text: $newNotes)
                Button("Cancel", role: .cancel) {
                    resetForm()
                }
                Button("Add") {
                    Task {
                        await addAccount()
                    }
                }
                .disabled(newAccountNumber.isEmpty)
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
            await loadSafeAccounts()
        }
    }
    
    private func loadSafeAccounts() async {
        isLoading = true
        do {
            let accounts = try await supabaseService.fetchVAISafeAccounts()
            await MainActor.run {
                self.safeAccounts = accounts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func addAccount() async {
        guard let userId = authManager.currentUser?.id else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
                self.isLoading = false
                self.showingAddAccount = false
            }
            return
        }
        
        isLoading = true
        do {
            let notes = newNotes.isEmpty ? nil : newNotes
            let newAccount = try await supabaseService.createVAISafeAccount(
                accountNumber: newAccountNumber,
                notes: notes,
                createdBy: userId
            )
            await MainActor.run {
                self.safeAccounts.insert(newAccount, at: 0)
                self.isLoading = false
                self.showingAddAccount = false
                self.resetForm()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.showingAddAccount = false
            }
        }
    }
    
    private func deleteAccount(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let account = safeAccounts[index]
                do {
                    try await supabaseService.deleteVAISafeAccount(id: account.id)
                    await MainActor.run {
                        self.safeAccounts.remove(at: index)
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to delete: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func resetForm() {
        newAccountNumber = ""
        newNotes = ""
    }
}
