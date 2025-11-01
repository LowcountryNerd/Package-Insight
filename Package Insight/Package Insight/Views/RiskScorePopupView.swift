import SwiftUI
import AVFoundation
struct RiskScorePopupView: View {
    let riskScore: RiskScoreDisplay
    let onDismiss: () -> Void
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            // Popup content
            VStack(spacing: 20) {
                // Risk Score
                Text("\(riskScore.score)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(Color(riskScore.color.systemColor))
                // Risk Message
                Text(riskScore.message)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                // Triggered Indices
                if !riskScore.triggeredIndices.isEmpty {
                    VStack(spacing: 8) {
                        Text("Triggered:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(riskScore.triggeredIndices.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                // Dismiss button
                Button("Close") {
                    onDismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .onAppear {
            speakRiskScore()
        }
    }
    private func speakRiskScore() {
        let utterance = AVSpeechUtterance(string: "Risk score: \(riskScore.score)")
        utterance.rate = 0.5
        utterance.volume = 1.0
        speechSynthesizer.speak(utterance)
    }
}
#Preview {
    RiskScorePopupView(
        riskScore: RiskScoreDisplay(
            score: 75,
            triggeredIndices: ["RSI", "OSI"],
            color: .red,
            message: "High Risk Detected"
        )
    ) {
        print("Dismissed")
    }
}