import SwiftUI
import Auth
struct UserDashboardView: View {
    @StateObject private var connectionManager = ConnectionStatusManager()
    @StateObject private var authManager = AuthManager()
    @State private var showingScannerView = false
    @State private var showingRiskPopup = false
    @State private var currentRiskScore: RiskScoreDisplay?
    @State private var showingScannerTest = false
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                VStack(spacing: 20) {
                    // Header
                    headerView
                    // Connection Status
                    connectionStatusView
                    // Scanner Button
                    scannerButton
                    Spacer()
                }
                .padding(.horizontal, 20)
                .onAppear {
                    connectionManager.checkConnections()
                }
                .blur(radius: showingRiskPopup ? 10 : 0)
                // Risk Score Popup
                if let riskScore = currentRiskScore, showingRiskPopup {
                    RiskScorePopupView(riskScore: riskScore) {
                        showingRiskPopup = false
                    }
                }
            }
            .navigationTitle("Package Scanner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Account") {
                            Text("Role: \(authManager.userRole.displayName)")
                                .foregroundColor(.secondary)
                                .disabled(true)
                            if let currentUser = authManager.currentUser {
                                Text("Email: \(currentUser.email ?? "Unknown")")
                                    .foregroundColor(.secondary)
                                    .disabled(true)
                            }
                            Divider()
                            Button("Scanner Test") {
                                showingScannerTest = true
                            }
                            Button("Sign Out") {
                                Task {
                                    await authManager.signOut()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingScannerView) {
            ScannerView()
        }
        .sheet(isPresented: $showingScannerTest) {
            ScannerTestView()
        }
    }
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            Text("Package Scanner")
                .font(.title2)
                .fontWeight(.bold)
            Text("Scan packages to assess risk and security")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    // MARK: - Connection Status View
    private var connectionStatusView: some View {
        VStack(spacing: 16) {
            Text("System Status")
                .font(.headline)
                .foregroundColor(.secondary)
            HStack(spacing: 20) {
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
    // MARK: - Scanner Button
    private var scannerButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingScannerView = true
            }) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                        .font(.title2)
                    Text("Scan Package")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            Text("Tap to scan a package barcode and analyze security risks")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
#Preview {
    UserDashboardView()
}