import SwiftUI
import Supabase
import Auth
struct ANIWatchlistView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
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
                    newAccountNumber = ""
                    newNotes = ""
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
        isLoading = true
        do {
            // This would need to be implemented in SupabaseService
            // For now, we'll show a placeholder
            await MainActor.run {
                self.errorMessage = "Add functionality requires server-side implementation"
                self.isLoading = false
                self.showingAddItem = false
                self.newAccountNumber = ""
                self.newNotes = ""
            }
        }
    }
    private func deleteItem(at offsets: IndexSet) {
        // This would need to be implemented in SupabaseService
        // For now, we'll show a placeholder
        errorMessage = "Delete functionality requires server-side implementation"
    }
}
#Preview {
    ANIWatchlistView()
}