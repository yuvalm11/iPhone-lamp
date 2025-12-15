import SwiftUI
import UIKit

@main
struct IPhoneLampApp: App {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 12/255, green: 18/255, blue: 30/255, alpha: 1)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.9, alpha: 1)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(white: 0.9, alpha: 1)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

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

