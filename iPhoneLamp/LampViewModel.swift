import SwiftUI
import Combine
import UIKit

final class LampViewModel: ObservableObject {
    @Published var intensity: Double = 0.6
    @Published var statusMessage: String = "Ready"
    @Published var selectedColor: Color = .orange
    @Published var isSending: Bool = false

    private let service: ESP32Service

    init(service: ESP32Service) {
        self.service = service
    }

    func turnOn() {
        send(label: "Power On") { try await self.service.turnOn() }
    }

    func turnOff() {
        send(label: "Power Off") { try await self.service.turnOff() }
    }

    func applySelectedColor() {
        let color = selectedColor

        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            statusMessage = "Failed to read color components"
            return
        }

        let red = Int(r * 255)
        let green = Int(g * 255)
        let blue = Int(b * 255)

        send(label: "Color") {
            try await self.service.setColor(r: red, g: green, b: blue)
        }
    }

    func applyIntensity(onEditingEnded: Bool) {
        guard onEditingEnded else { return }
        let value = intensity
        send(label: "Intensity \(Int(value * 100))%") {
            try await self.service.setIntensity(value)
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

