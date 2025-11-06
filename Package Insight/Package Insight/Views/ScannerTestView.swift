import SwiftUI

struct ScannerTestView: View {
    @StateObject private var scannerManager = SocketMobileScannerManager.shared
    @State private var scanHistory: [ScannedBarcodeData] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Connection Status
                connectionStatusView
                
                Divider()
                
                // Scanned Data Section
                scannedDataView
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scanner Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        scanHistory.removeAll()
                    }
                    .foregroundColor(.red)
                    .disabled(scanHistory.isEmpty)
                }
            }
        }
        .onAppear {
            setupScannerDelegate()
            if !scannerManager.isInitialized {
                scannerManager.initializeScanner()
            }
            scannerManager.startScanning()
        }
        .onReceive(scannerManager.$lastScannedData) { data in
            if let data = data {
                scanHistory.insert(data, at: 0)
            }
        }
    }
    
    // MARK: - Connection Status View
    private var connectionStatusView: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 20, height: 20)
                
                Text(scannerManager.scannerStatus.displayName)
                    .font(.headline)
                    .foregroundColor(statusColor)
                
                Spacer()
            }
            
            if let deviceInfo = scannerManager.connectedDeviceInfo {
                HStack {
                    Text("Device:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(deviceInfo)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch scannerManager.scannerStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
    
    // MARK: - Scanned Data View
    private var scannedDataView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Scanned Data")
                    .font(.headline)
                Spacer()
                if !scanHistory.isEmpty {
                    Text("\(scanHistory.count) scan\(scanHistory.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if scanHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No scans yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Scan a barcode or label to see the raw data here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(scanHistory.enumerated()), id: \.offset) { index, scanData in
                            ScannedDataCard(scanData: scanData, index: index + 1)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupScannerDelegate() {
        scannerManager.setDelegate(ScannerTestDelegate(scannerTestView: self))
    }
    
    func onScannerDataReceived(_ data: ScannedBarcodeData) {
        print("[ScannerTest] Received data: \(data.rawData)")
    }
}

// MARK: - Scanned Data Card
struct ScannedDataCard: View {
    let scanData: ScannedBarcodeData
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Scan #\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(scanData.timestamp, formatter: timeFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Raw Data - Prominent Display
            VStack(alignment: .leading, spacing: 6) {
                Text("Raw Data:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(scanData.rawData)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
            
            // Metadata
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let symbology = scanData.symbology {
                        Label(symbology, systemImage: "barcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let device = scanData.deviceInfo {
                        Label(device, systemImage: "scanner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(scanData.dataLength) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }
}

// MARK: - Scanner Test Delegate
class ScannerTestDelegate: SocketMobileScannerManagerDelegate {
    private var scannerTestView: ScannerTestView?
    
    init(scannerTestView: ScannerTestView) {
        self.scannerTestView = scannerTestView
    }
    
    func scannerDidConnect(_ deviceInfo: String) {
        print("[ScannerTest] Connected: \(deviceInfo)")
    }
    
    func scannerDidDisconnect() {
        print("[ScannerTest] Disconnected")
    }
    
    func scannerDidReceiveData(_ data: ScannedBarcodeData) {
        scannerTestView?.onScannerDataReceived(data)
    }
    
    func scannerDidEncounterError(_ error: Error) {
        print("[ScannerTest] Error: \(error.localizedDescription)")
    }
    
    func scannerDidDiscoverDevice(_ deviceInfo: String) {
        print("[ScannerTest] Device discovered: \(deviceInfo)")
    }
}
