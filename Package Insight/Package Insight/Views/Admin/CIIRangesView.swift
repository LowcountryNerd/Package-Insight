import SwiftUI
import Supabase
import Auth

struct CIIRangesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var authManager = AuthManager()
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
        guard let userId = authManager.currentUser?.id else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
                self.isLoading = false
                self.showingAddRange = false
            }
            return
        }
        
        guard let minValue = Double(newMinValue),
              let maxValue = Double(newMaxValue),
              let points = Int(newPoints) else {
            await MainActor.run {
                self.errorMessage = "Invalid input values"
                self.isLoading = false
                self.showingAddRange = false
            }
            return
        }
        
        isLoading = true
        do {
            let notes = newNotes.isEmpty ? nil : newNotes
            let newRange = try await supabaseService.createCIIRange(
                minValue: minValue,
                maxValue: maxValue,
                points: points,
                notes: notes,
                createdBy: userId
            )
            await MainActor.run {
                self.ciiRanges.insert(newRange, at: 0)
                self.isLoading = false
                self.showingAddRange = false
                self.resetForm()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.showingAddRange = false
            }
        }
    }
    
    private func deleteRange(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let range = ciiRanges[index]
                do {
                    try await supabaseService.deleteCIIRange(id: range.id)
                    await MainActor.run {
                        self.ciiRanges.remove(at: index)
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
        newMinValue = ""
        newMaxValue = ""
        newPoints = ""
        newNotes = ""
    }
}
