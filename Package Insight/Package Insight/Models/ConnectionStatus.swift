import Foundation
import Combine
// MARK: - Connection Status Manager
class ConnectionStatusManager: ObservableObject {
    @Published var fedexStatus: ConnectionStatus = .disconnected
    @Published var databaseStatus: ConnectionStatus = .disconnected
    @Published var scannerStatus: ConnectionStatus = .disconnected
    private var scannerManager = SocketMobileScannerManager.shared
    private var cancellables = Set<AnyCancellable>()
    init() {
        setupScannerStatusObserver()
    }
    var isAllConnected: Bool {
        return fedexStatus == .connected &&
               databaseStatus == .connected &&
               scannerStatus == .connected
    }
    var statusMessage: String {
        if isAllConnected {
            return "Scan your package"
        } else {
            return "Waiting for connections…"
        }
    }
    var overallStatus: String {
        if isAllConnected {
            return "All systems operational."
        } else if databaseStatus == .error || fedexStatus == .error || scannerStatus == .error {
            return "System error detected."
        } else if databaseStatus == .connecting || fedexStatus == .connecting || scannerStatus == .connecting {
            return "Establishing connections..."
        } else {
            return "Waiting for connections…"
        }
    }
    // MARK: - Private Methods
    private func setupScannerStatusObserver() {
        // Observe scanner status changes from SocketMobileScannerManager
        scannerManager.$scannerStatus
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .connected:
                        self?.scannerStatus = .connected
                    case .disconnected:
                        self?.scannerStatus = .disconnected
                    case .connecting:
                        self?.scannerStatus = .connecting
                    case .error:
                        self?.scannerStatus = .error
                    }
                }
            }
            .store(in: &cancellables)
    }
    // MARK: - Public Methods
    // Check real connections
    func checkConnections() {
        print(" Checking all connections...")
        // Check Supabase database connection
        Task {
            let supabaseService = SupabaseService.shared
            await supabaseService.testConnection()
            await MainActor.run {
                self.databaseStatus = supabaseService.isConnected ? .connected : .error
            }
        }
        // FedEx connection check (will be implemented with Edge Functions)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fedexStatus = .connected
        }
        // Reinitialize scanner if already initialized (for retry), otherwise initialize
        if scannerManager.isInitialized {
            print(" Reinitializing scanner for retry...")
            scannerManager.reinitializeScanner()
        } else {
            print(" Initializing scanner for the first time...")
            scannerManager.initializeScanner()
        }
        // Start scanning after a brief delay to allow initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.scannerManager.startScanning()
        }
    }
    func updateScannerStatus(_ status: ConnectionStatus) {
        DispatchQueue.main.async {
            self.scannerStatus = status
        }
    }
    func startScanner() {
        scannerManager.startScanning()
    }
    func stopScanner() {
        scannerManager.stopScanning()
    }
    func disconnectScanner() {
        scannerManager.disconnectDevice()
    }
}
// MARK: - Connection Status Enum
enum ConnectionStatus: String, CaseIterable {
    case connected = "connected"
    case disconnected = "disconnected"
    case connecting = "connecting"
    case error = "error"
    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .error: return "Error"
        }
    }
    var color: String {
        switch self {
        case .connected: return "green"
        case .disconnected: return "gray"
        case .connecting: return "orange"
        case .error: return "red"
        }
    }
}