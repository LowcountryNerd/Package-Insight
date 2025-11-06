import SwiftUI
import Supabase
import Auth

struct OSIRulesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var authManager = AuthManager()
    @State private var osiRules: [OSIRule] = []
    @State private var isLoading = false
    @State private var showingAddRule = false
    @State private var newPattern = ""
    @State private var newPoints = ""
    @State private var newNotes = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading OSI rules...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(osiRules) { rule in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Pattern: \(rule.pattern)")
                                        .font(.headline)
                                    Spacer()
                                    HStack {
                                        Text("\(rule.points) pts")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                        if rule.active {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                        } else {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                    }
                                }
                                if let notes = rule.notes, !notes.isEmpty {
                                    Text("Notes: \(notes)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text("Added: \(DateFormatter.shortDate.string(from: rule.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteRule)
                    }
                    .refreshable {
                        await loadOSIRules()
                    }
                }
            }
            .navigationTitle("OSI Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddRule = true
                    }
                }
            }
            .alert("Add OSI Rule", isPresented: $showingAddRule) {
                TextField("Pattern (Regex)", text: $newPattern)
                TextField("Points", text: $newPoints)
                    .keyboardType(.numberPad)
                TextField("Notes (Optional)", text: $newNotes)
                Button("Cancel", role: .cancel) {
                    resetForm()
                }
                Button("Add") {
                    Task {
                        await addRule()
                    }
                }
                .disabled(newPattern.isEmpty || newPoints.isEmpty)
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
            await loadOSIRules()
        }
    }
    
    private func loadOSIRules() async {
        isLoading = true
        do {
            let rules = try await supabaseService.fetchOSIRules()
            await MainActor.run {
                self.osiRules = rules
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func addRule() async {
        guard let userId = authManager.currentUser?.id else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
                self.isLoading = false
                self.showingAddRule = false
            }
            return
        }
        
        guard let points = Int(newPoints) else {
            await MainActor.run {
                self.errorMessage = "Invalid points value"
                self.isLoading = false
                self.showingAddRule = false
            }
            return
        }
        
        isLoading = true
        do {
            let notes = newNotes.isEmpty ? nil : newNotes
            let newRule = try await supabaseService.createOSIRule(
                pattern: newPattern,
                points: points,
                notes: notes,
                createdBy: userId
            )
            await MainActor.run {
                self.osiRules.insert(newRule, at: 0)
                self.isLoading = false
                self.showingAddRule = false
                self.resetForm()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.showingAddRule = false
            }
        }
    }
    
    private func deleteRule(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let rule = osiRules[index]
                do {
                    try await supabaseService.deleteOSIRule(id: rule.id)
                    await MainActor.run {
                        self.osiRules.remove(at: index)
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
        newPattern = ""
        newPoints = ""
        newNotes = ""
    }
}
