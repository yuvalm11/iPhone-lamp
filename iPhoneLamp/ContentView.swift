import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LampViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                powerRow
                colorRow
                intensityRow
                statusRow
            }
            .padding(24)
            .navigationTitle("ESP32 Lamp")
        }
    }

    private var powerRow: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.turnOn()
            } label: {
                label(icon: "lightbulb.fill", title: "On", tint: .yellow)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSending)

            Button {
                viewModel.turnOff()
            } label: {
                label(icon: "lightbulb.slash", title: "Off", tint: .secondary)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isSending)
        }
    }

    private var colorRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.colors) { choice in
                        Button {
                            viewModel.applyColor(choice)
                        } label: {
                            VStack {
                                Circle()
                                    .fill(choice.color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(viewModel.selectedColor == choice ? Color.primary : .clear, lineWidth: 2)
                                    )
                                Text(choice.name)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSending)
                    }
                }
            }
        }
    }

    private var intensityRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intensity")
                .font(.headline)
            Slider(value: $viewModel.intensity, in: 0...1, onEditingChanged: viewModel.applyIntensity)
            Text("\(Int(viewModel.intensity * 100))%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusRow: some View {
        HStack {
            Image(systemName: viewModel.isSending ? "wifi.exclamationmark" : "checkmark.circle")
                .foregroundStyle(viewModel.isSending ? .orange : .green)
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func label(icon: String, title: String, tint: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .foregroundStyle(tint)
    }
}

#Preview {
    let service = ESP32Service(baseURL: URL(string: "http://192.168.4.1")!)
    let viewModel = LampViewModel(service: service)
    return ContentView(viewModel: viewModel)
}

