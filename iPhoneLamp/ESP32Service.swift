import Foundation

/// Minimal helper that knows how to talk to the ESP32 over HTTP.
/// Update `baseURL` to match the device IP (for many sketches this is 192.168.4.1 when in AP mode).
struct ESP32Service {
    var baseURL: URL
    var session: URLSession = .shared

    @discardableResult
    private func send(path: String, jsonBody: [String: Any]? = nil) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"

        if let jsonBody {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    func turnOn() async throws {
        try await send(path: "on")
    }

    func turnOff() async throws {
        try await send(path: "off")
    }

    func setColor(r: Int, g: Int, b: Int) async throws {
        try await send(path: "color", jsonBody: ["r": r, "g": g, "b": b])
    }

    func setIntensity(_ value: Double) async throws {
        // Value expected between 0...1 on the ESP32 side.
        try await send(path: "intensity", jsonBody: ["value": value])
    }
}

