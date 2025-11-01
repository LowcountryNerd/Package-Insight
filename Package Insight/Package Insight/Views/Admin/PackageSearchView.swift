import SwiftUI
import Supabase
import Auth
struct PackageSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var packages: [PackageRecord] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedScoreRange: ScoreRange = .all
    @State private var dateRange: DateRange = .all
    @State private var showingFilters = false
    @State private var errorMessage: String?
    enum ScoreRange: String, CaseIterable {
        case all = "All Scores"
        case low = "Low (0-25)"
        case medium = "Medium (26-75)"
        case high = "High (76-100)"
        var minScore: Int? {
            switch self {
            case .all: return nil
            case .low: return 0
            case .medium: return 26
            case .high: return 76
            }
        }
        var maxScore: Int? {
            switch self {
            case .all: return nil
            case .low: return 25
            case .medium: return 75
            case .high: return 100
            }
        }
    }
    enum DateRange: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by tracking number, ANI, or address...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            Task {
                                await searchPackages()
                            }
                        }
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                // Filter Summary
                if selectedScoreRange != .all || dateRange != .all {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            if selectedScoreRange != .all {
                                FilterChip(text: selectedScoreRange.rawValue) {
                                    selectedScoreRange = .all
                                }
                            }
                            if dateRange != .all {
                                FilterChip(text: dateRange.rawValue) {
                                    dateRange = .all
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                if isLoading {
                    ProgressView("Searching packages...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if packages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "package")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No packages found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        if !searchText.isEmpty || selectedScoreRange != .all || dateRange != .all {
                            Text("Try adjusting your search criteria")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Scan some packages to see them here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(packages) { package in
                            PackageRowView(package: package)
                        }
                    }
                    .refreshable {
                        await searchPackages()
                    }
                }
            }
            .navigationTitle("Package Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Filters") {
                            showingFilters = true
                        }
                        Button("Export") {
                            Task {
                                await exportPackages()
                            }
                        }
                        .disabled(packages.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(
                    selectedScoreRange: $selectedScoreRange,
                    dateRange: $dateRange
                ) {
                    Task {
                        await searchPackages()
                    }
                }
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
            await searchPackages()
        }
    }
    private func searchPackages() async {
        isLoading = true
        do {
            // This would need to be implemented in SupabaseService
            // For now, we'll show a placeholder
            await MainActor.run {
                self.errorMessage = "Search functionality requires server-side implementation"
                self.isLoading = false
            }
        }
    }
    private func exportPackages() async {
        // This would need to be implemented
        errorMessage = "Export functionality requires implementation"
    }
}
struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    var body: some View {
        HStack {
            Text(text)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}
struct PackageRowView: View {
    let package: PackageRecord
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(package.trackingNumber ?? "No Tracking")
                    .font(.headline)
                Spacer()
                ScoreBadge(score: package.totalScore)
            }
            if let ani = package.ani {
                Text("ANI: \(ani)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let adi = package.adi {
                Text("Address: \(adi)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            if !package.triggeredIndices.isEmpty {
                Text("Triggers: \(package.triggeredIndices.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            Text("Scanned: \(DateFormatter.shortDate.string(from: package.createdAt))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
struct ScoreBadge: View {
    let score: Int
    var body: some View {
        Text("\(score)")
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(scoreColor)
            .cornerRadius(8)
    }
    private var scoreColor: Color {
        switch score {
        case 0...25: return .green
        case 26...75: return .orange
        default: return .red
        }
    }
}
struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedScoreRange: PackageSearchView.ScoreRange
    @Binding var dateRange: PackageSearchView.DateRange
    let onApply: () -> Void
    var body: some View {
        NavigationView {
            Form {
                Section("Risk Score") {
                    Picker("Score Range", selection: $selectedScoreRange) {
                        ForEach(PackageSearchView.ScoreRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Date Range") {
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(PackageSearchView.DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}
#Preview {
    PackageSearchView()
}