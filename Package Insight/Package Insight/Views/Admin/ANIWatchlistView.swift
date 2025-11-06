import SwiftUI
import Supabase
import Auth

struct ANIWatchlistView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var authManager = AuthManager()
    @State private var watchlistItems: [ANIWatchlistItem] = []
    @State private var isLoading = false
    @State private var showingAddItem = false
    @State private var newAccountNumber = ""
    @State private var newNotes = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading watchlist...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(watchlistItems) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Account: \(item.accountNumber)")
                                    .font(.headline)
                                if let notes = item.notes, !notes.isEmpty {
                                    Text("Notes: \(notes)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text("Added: \(DateFormatter.shortDate.string(from: item.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteItem)
                    }
                    .refreshable {
                        await loadWatchlist()
                    }
                }
            }
            .navigationTitle("ANI Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddItem = true
                    }
                }
            }
            .alert("Add Account to Watchlist", isPresented: $showingAddItem) {
                TextField("Account Number", text: $newAccountNumber)
                TextField("Notes (Optional)", text: $newNotes)
                Button("Cancel", role: .cancel) {
                    resetForm()
                }
                Button("Add") {
                    Task {
                        await addItem()
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
            await loadWatchlist()
        }
    }
    
    private func loadWatchlist() async {
        isLoading = true
        do {
            let items = try await supabaseService.fetchANIWatchlist()
            await MainActor.run {
                self.watchlistItems = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func addItem() async {
        guard let userId = authManager.currentUser?.id else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
                self.isLoading = false
                self.showingAddItem = false
            }
            return
        }
        
        isLoading = true
        do {
            let notes = newNotes.isEmpty ? nil : newNotes
            let newItem = try await supabaseService.createANIWatchlistItem(
                accountNumber: newAccountNumber,
                notes: notes,
                createdBy: userId
            )
            await MainActor.run {
                self.watchlistItems.insert(newItem, at: 0)
                self.isLoading = false
                self.showingAddItem = false
                self.resetForm()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.showingAddItem = false
            }
        }
    }
    
    private func deleteItem(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let item = watchlistItems[index]
                do {
                    try await supabaseService.deleteANIWatchlistItem(id: item.id)
                    await MainActor.run {
                        self.watchlistItems.remove(at: index)
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
