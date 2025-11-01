import SwiftUI
import Supabase
import Auth
struct CIIRangesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var ciiRanges: [CIIRange] = []
    @State private var isLoading = false
    @State private var showingAddRange = false
    @State private var newMinValue = ""
    @State private var newMaxValue = ""
    @State private var newPoints = ""
    @State private var newNotes = ""
    @State private var errorMessage: String?
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading CII ranges...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(ciiRanges) { range in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(range.minValue, specifier: "%.3f") - \(range.maxValue, specifier: "%.3f")")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(range.points) pts")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                if let notes = range.notes, !notes.isEmpty {
                                    Text("Notes: \(notes)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text("Added: \(DateFormatter.shortDate.string(from: range.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteRange)
                    }
                    .refreshable {
                        await loadCIIRanges()
                    }
                }
            }
            .navigationTitle("CII Risk Ranges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddRange = true
                    }
                }
            }
            .alert("Add CII Range", isPresented: $showingAddRange) {
                TextField("Min Value", text: $newMinValue)
                    .keyboardType(.decimalPad)
                TextField("Max Value", text: $newMaxValue)
                    .keyboardType(.decimalPad)
                TextField("Points", text: $newPoints)
                    .keyboardType(.numberPad)
                TextField("Notes (Optional)", text: $newNotes)
                Button("Cancel", role: .cancel) {
                    resetForm()
                }
                Button("Add") {
                    Task {
                        await addRange()
                    }
                }
                .disabled(newMinValue.isEmpty || newMaxValue.isEmpty || newPoints.isEmpty)
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
            await loadCIIRanges()
        }
    }
    private func loadCIIRanges() async {
        isLoading = true
        do {
            let ranges = try await supabaseService.fetchCIIRanges()
            await MainActor.run {
                self.ciiRanges = ranges
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    private func addRange() async {
        isLoading = true
        do {
            // This would need to be implemented in SupabaseService
            // For now, we'll show a placeholder
            await MainActor.run {
                self.errorMessage = "Add functionality requires server-side implementation"
                self.isLoading = false
                self.showingAddRange = false
                resetForm()
            }
        }
    }
    private func deleteRange(at offsets: IndexSet) {
        // This would need to be implemented in SupabaseService
        // For now, we'll show a placeholder
        errorMessage = "Delete functionality requires server-side implementation"
    }
    private func resetForm() {
        newMinValue = ""
        newMaxValue = ""
        newPoints = ""
        newNotes = ""
    }
}
#Preview {
    CIIRangesView()
}