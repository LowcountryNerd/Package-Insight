import SwiftUI

struct LogViewerView: View {
    let logMessages: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredLogs: [String] {
        if searchText.isEmpty {
            return logMessages
        }
        return logMessages.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search logs...", text: $searchText)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                
                if filteredLogs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No logs found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if !searchText.isEmpty {
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(filteredLogs.enumerated()), id: \.offset) { index, log in
                                LogRowView(log: log)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Scanner Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private var shareText: String {
        let header = """
========== Package Insight Scanner Logs ==========
Generated: \(Date())
Total Logs: \(logMessages.count)
Filtered: \(filteredLogs.count)

============================================

"""
        return header + filteredLogs.joined(separator: "\n")
    }
}

struct LogRowView: View {
    let log: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(log)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(logColor)
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(backgroundColor.opacity(0.3))
        .cornerRadius(4)
    }
    
    private var logColor: Color {
        if log.contains("ERROR") || log.contains("Failed") {
            return .red
        } else if log.contains("Success") || log.contains("connected") {
            return .green
        } else if log.contains("INFO") {
            return .blue
        }
        return .primary
    }
    
    private var backgroundColor: Color {
        if log.contains("ERROR") || log.contains("Failed") {
            return .red
        } else if log.contains("Success") || log.contains("connected") {
            return .green
        }
        return .clear
    }
}
