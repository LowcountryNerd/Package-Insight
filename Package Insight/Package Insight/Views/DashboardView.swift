import SwiftUI
struct AdminDashboardView: View {
    @StateObject private var connectionManager = ConnectionStatusManager()
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var authManager = AuthManager()
    @State private var showingScannerView = false
    @State private var showingRiskPopup = false
    @State private var currentRiskScore: RiskScoreDisplay?
    @State private var showingUserManagement = false
    @State private var showingANIWatchlist = false
    @State private var showingVAISafeAccounts = false
    @State private var showingCIIRanges = false
    @State private var showingOSIRules = false
    @State private var showingRSIRules = false
    @State private var showingPackageSearch = false
    @State private var showingScannerTest = false
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                VStack(spacing: 30) {
                    // Connection Status Indicators
                    connectionStatusView
                    Spacer()
                    // Main Status Message
                    mainStatusMessage
                    Spacer()
                    // Action Button
                    actionButton
                    Spacer()
                }
                .padding()
                .onAppear {
                    connectionManager.checkConnections()
                }
                // Risk Score Popup Overlay
                if showingRiskPopup, let riskScore = currentRiskScore {
                    RiskScorePopupView(riskScore: riskScore) {
                        showingRiskPopup = false
                    }
                }
            }
                    .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.large)
                   .toolbar {
                       ToolbarItem(placement: .navigationBarTrailing) {
                           Menu {
                               if authManager.isAdmin {
                                   Section("Admin") {
                                       Button("User Management") {
                                           showingUserManagement = true
                                       }
                                       Button("ANI Watchlist") {
                                           showingANIWatchlist = true
                                       }
                                       Button("VAI Safe Accounts") {
                                           showingVAISafeAccounts = true
                                       }
                                       Button("CII Ranges") {
                                           showingCIIRanges = true
                                       }
                                       Button("OSI Rules") {
                                           showingOSIRules = true
                                       }
                                       Button("RSI Rules") {
                                           showingRSIRules = true
                                       }
                                              Button("Package Search") {
                                                  showingPackageSearch = true
                                              }
                                              Button("Scanner Test") {
                                                  showingScannerTest = true
                                              }
                                   }
                                   Divider()
                               }
                               Section("Account") {
                                   Button("Sign Out") {
                                       Task {
                                           await authManager.signOut()
                                       }
                                   }
                               }
                           } label: {
                               HStack {
                                   if authManager.isAdmin {
                                       Image(systemName: "crown.fill")
                                           .foregroundColor(.yellow)
                                   }
                                   Image(systemName: "person.circle")
                               }
                           }
                       }
                   }
        }
        .sheet(isPresented: $showingScannerView) {
            ScannerView()
        }
        .sheet(isPresented: $showingUserManagement) {
            UserManagementView()
        }
        .sheet(isPresented: $showingANIWatchlist) {
            ANIWatchlistView()
        }
        .sheet(isPresented: $showingVAISafeAccounts) {
            VAISafeAccountsView()
        }
        .sheet(isPresented: $showingCIIRanges) {
            CIIRangesView()
        }
        .sheet(isPresented: $showingOSIRules) {
            OSIRulesView()
        }
        .sheet(isPresented: $showingRSIRules) {
            RSIRulesView()
        }
               .sheet(isPresented: $showingPackageSearch) {
                   PackageSearchView()
               }
               .sheet(isPresented: $showingScannerTest) {
                   ScannerTestView()
               }
    }
    // MARK: - Connection Status View
    private var connectionStatusView: some View {
        VStack(spacing: 16) {
            Text("System Status")
                .font(.headline)
                .foregroundColor(.secondary)
            HStack(spacing: 20) {
                StatusIndicator(
                    title: "FedEx",
                    status: connectionManager.fedexStatus
                )
                StatusIndicator(
                    title: "Database",
                    status: connectionManager.databaseStatus
                )
                StatusIndicator(
                    title: "Scanner",
                    status: connectionManager.scannerStatus
                )
            }
        }
    }
    // MARK: - Main Status Message
    private var mainStatusMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: connectionManager.isAllConnected ? "barcode.viewfinder" : "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(connectionManager.isAllConnected ? .green : .orange)
            Text(connectionManager.statusMessage)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
    }
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            if connectionManager.isAllConnected {
                showingScannerView = true
            } else {
                connectionManager.checkConnections()
            }
        }) {
            HStack {
                Image(systemName: connectionManager.isAllConnected ? "barcode.viewfinder" : "arrow.clockwise")
                Text(connectionManager.isAllConnected ? "Start Scanning" : "Retry Connection")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(connectionManager.isAllConnected ? Color.blue : Color.orange)
            .cornerRadius(12)
        }
        .disabled(connectionManager.scannerStatus == .connecting)
    }
}
// MARK: - Status Indicator Component
struct StatusIndicator: View {
    let title: String
    let status: ConnectionStatus
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(status.color))
                .frame(width: 16, height: 16)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(status.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
#Preview {
    AdminDashboardView()
}