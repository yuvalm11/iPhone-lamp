import SwiftUI

struct ColorChoice: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
    let rgb: (Int, Int, Int)
}

@MainActor
final class LampViewModel: ObservableObject {
    @Published var intensity: Double = 0.6
    @Published var statusMessage: String = "Ready"
    @Published var selectedColor: ColorChoice
    @Published var isSending: Bool = false

    let colors: [ColorChoice] = [
        ColorChoice(name: "Warm", color: .orange, rgb: (255, 184, 144)),
        ColorChoice(name: "Cool", color: .cyan, rgb: (170, 210, 255)),
        ColorChoice(name: "Red", color: .red, rgb: (255, 64, 64)),
        ColorChoice(name: "Green", color: .green, rgb: (80, 200, 120)),
        ColorChoice(name: "Blue", color: .blue, rgb: (96, 140, 255))
    ]

    private let service: ESP32Service

    init(service: ESP32Service) {
        self.service = service
        self.selectedColor = colors.first!
    }

    func turnOn() {
        send(label: "Power On") { try await service.turnOn() }
    }

    func turnOff() {
        send(label: "Power Off") { try await service.turnOff() }
    }

    func applyColor(_ choice: ColorChoice) {
        selectedColor = choice
        send(label: "Color \(choice.name)") {
            try await service.setColor(r: choice.rgb.0, g: choice.rgb.1, b: choice.rgb.2)
        }
    }

    func applyIntensity(onEditingEnded: Bool) {
        guard onEditingEnded else { return }
        let value = intensity
        send(label: "Intensity \(Int(value * 100))%") {
            try await service.setIntensity(value)
        }
    }

    private func send(label: String, action: @escaping () async throws -> Void) {
        isSending = true
        statusMessage = "Sending \(label.lowercased())..."

        Task { [weak self] in
            guard let self else { return }
            do {
                try await action()
                await MainActor.run {
                    self.statusMessage = "\(label) sent"
                    self.isSending = false
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Failed to send \(label.lowercased()): \(error.localizedDescription)"
                    self.isSending = false
                }
            }
        }
    }
}

