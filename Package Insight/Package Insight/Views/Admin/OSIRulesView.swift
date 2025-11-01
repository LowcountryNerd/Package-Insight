import SwiftUI
import Supabase
import Auth
struct OSIRulesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
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
        isLoading = true
        do {
            // This would need to be implemented in SupabaseService
            // For now, we'll show a placeholder
            await MainActor.run {
                self.errorMessage = "Add functionality requires server-side implementation"
                self.isLoading = false
                self.showingAddRule = false
                resetForm()
            }
        }
    }
    private func deleteRule(at offsets: IndexSet) {
        // This would need to be implemented in SupabaseService
        // For now, we'll show a placeholder
        errorMessage = "Delete functionality requires server-side implementation"
    }
    private func resetForm() {
        newPattern = ""
        newPoints = ""
        newNotes = ""
    }
}
#Preview {
    OSIRulesView()
}