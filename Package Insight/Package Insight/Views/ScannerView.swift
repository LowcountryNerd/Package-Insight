import SwiftUI
struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socketScannerManager = SocketMobileScannerManager.shared
    @State private var showingRiskPopup = false
    @State private var currentRiskScore: RiskScoreDisplay?
    @State private var isScanning = false
    @State private var lastScannedData: ScannedBarcodeData?
    var body: some View {
        NavigationView {
            ZStack {
                // Scanner Interface
                VStack(spacing: 30) {
                    // Scanner Status
                    scannerStatusView
                    Spacer()
                    // Scanning Instructions
                    scanningInstructionsView
                    Spacer()
                    // Scan Button
                    scanButton
                    Spacer()
                }
                .padding()
                // Risk Score Popup Overlay
                if showingRiskPopup, let riskScore = currentRiskScore {
                    RiskScorePopupView(riskScore: riskScore) {
                        showingRiskPopup = false
                        currentRiskScore = nil
                    }
                }
            }
            .navigationTitle("Package Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupScannerDelegate()
            if !socketScannerManager.isInitialized {
                socketScannerManager.initializeScanner()
            }
            socketScannerManager.startScanning()
        }
        .onDisappear {
            socketScannerManager.stopScanning()
        }
        .onReceive(socketScannerManager.$lastScannedData) { data in
            if let data = data {
                handleScannedData(data)
            }
        }
    }
    // MARK: - Scanner Status View
    private var scannerStatusView: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color(socketScannerManager.scannerStatus.color))
                .frame(width: 20, height: 20)
            Text(socketScannerManager.scannerStatus.displayName)
                .font(.headline)
                .foregroundColor(Color(socketScannerManager.scannerStatus.color))
            if let deviceInfo = socketScannerManager.connectedDeviceInfo {
                Text("Device: \(deviceInfo)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let lastScan = lastScannedData {
                Text("Last scan: \(lastScan.timestamp, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    // MARK: - Scanning Instructions
    private var scanningInstructionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            Text("Position barcode in viewfinder")
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            Text("Scan packages to analyze risk scores")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    // MARK: - Scan Button
    private var scanButton: some View {
        Button(action: {
            // Simulate scan for demo purposes
            simulateScan()
        }) {
            HStack {
                if isScanning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "barcode.viewfinder")
                }
                Text(isScanning ? "Scanning..." : "Scan Package")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isScanning ? Color.gray : Color.blue)
            .cornerRadius(12)
        }
        .disabled(isScanning || !isScannerConnected)
    }
    // MARK: - Computed Properties
    private var isScannerConnected: Bool {
        switch socketScannerManager.scannerStatus {
        case .connected:
            return true
        default:
            return false
        }
    }
    // MARK: - Helper Methods
    private func setupScannerDelegate() {
        socketScannerManager.setDelegate(ScannerViewDelegate(scannerView: self))
    }
    private func handleScannedData(_ data: ScannedBarcodeData) {
        lastScannedData = data
        
        // Parse barcode data
        let parsedData = BarcodeParser.parse(data.rawData)
        processPackage(parsedData)
    }
    private func processPackage(_ parsedData: ParsedBarcode) {
        // Simulate API call to backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate risk score calculation
            let simulatedScore = Int.random(in: 0...100)
            let simulatedIndices = simulatedScore > 25 ? ["RSI", "OSI"] : []
            let riskScore = RiskScoreDisplay(
                score: simulatedScore,
                triggeredIndices: simulatedIndices,
                color: RiskScoreDisplay.RiskColor.fromScore(simulatedScore),
                message: simulatedScore == 0 ? "Safe" : "Risk Level: \(simulatedScore)"
            )
            self.currentRiskScore = riskScore
            self.showingRiskPopup = true
            self.isScanning = false
        }
    }
    private func simulateScan() {
        isScanning = true
        // Simulate scan delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let mockBarcodeData = ScannedBarcodeData(
                rawData: "1Z999AA1234567890",
                deviceInfo: socketScannerManager.connectedDeviceInfo
            )
            handleScannedData(mockBarcodeData)
        }
    }
    // MARK: - Public Methods for Delegate
    func onScannerDataReceived(_ data: ScannedBarcodeData) {
        handleScannedData(data)
    }
    func onScannerConnected(_ deviceInfo: String) {
        print(" Scanner connected: \(deviceInfo)")
    }
    func onScannerDisconnected() {
        print(" Scanner disconnected")
    }
    func onScannerError(_ error: Error) {
        print(" Scanner error: \(error.localizedDescription)")
    }
    func onScannerDeviceDiscovered(_ deviceInfo: String) {
        print(" Scanner device discovered: \(deviceInfo)")
    }
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }
}
// MARK: - Scanner View Delegate
class ScannerViewDelegate: SocketMobileScannerManagerDelegate {
    private var scannerView: ScannerView?
    init(scannerView: ScannerView) {
        self.scannerView = scannerView
    }
    func scannerDidConnect(_ deviceInfo: String) {
        scannerView?.onScannerConnected(deviceInfo)
    }
    func scannerDidDisconnect() {
        scannerView?.onScannerDisconnected()
    }
    func scannerDidReceiveData(_ data: ScannedBarcodeData) {
        scannerView?.onScannerDataReceived(data)
    }
    func scannerDidEncounterError(_ error: Error) {
        scannerView?.onScannerError(error)
    }
    func scannerDidDiscoverDevice(_ deviceInfo: String) {
        scannerView?.onScannerDeviceDiscovered(deviceInfo)
    }
}
#Preview {
    ScannerView()
}