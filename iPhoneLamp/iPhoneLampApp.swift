import SwiftUI

@main
struct IPhoneLampApp: App {
    private let viewModel = LampViewModel(
        service: ESP32Service(
            baseURL: URL(string: "http://192.168.4.1")! // Update to match your ESP32 IP
        )
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}

