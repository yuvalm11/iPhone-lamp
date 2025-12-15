import SwiftUI


struct ContentView: View {
    @ObservedObject var viewModel: LampViewModel
    @State private var isOn: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 12/255, green: 18/255, blue: 30/255)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    powerToggle
                    colorRow
                    intensityRow
                    statusRow
                }
                .padding(24)
                .foregroundStyle(Color(white: 0.9))
                .navigationTitle("Smart Lamp")
            }
        }
    }

    private var powerToggle: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: isOn ? "lightbulb.fill" : "lightbulb.slash")
                    .foregroundStyle(isOn ? .yellow : Color(white: 0.8))
                Text(isOn ? "Lamp On" : "Lamp Off")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(SwitchToggleStyle(tint: .yellow))
        .disabled(viewModel.isSending)
        .onChange(of: isOn) { oldValue, newValue in
            if newValue {
                viewModel.turnOn()
            } else {
                viewModel.turnOff()
            }
        }
    }

    private var colorRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)

            HStack {
                Spacer()
                ColorPicker("",
                            selection: $viewModel.selectedColor,
                            supportsOpacity: false)
                .labelsHidden()
                .frame(width: 64, height: 64)
                .scaleEffect(1.25)
                .disabled(viewModel.isSending)
                .onChange(of: viewModel.selectedColor) { _, _ in
                    viewModel.applySelectedColor()
                }
                Spacer()
            }
        }
    }

    private var intensityRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intensity")
                .font(.headline)
            Slider(value: $viewModel.intensity, in: 0...1, onEditingChanged: viewModel.applyIntensity)
                .tint(.white)
                .background(
                    Capsule()
                        .fill(Color(white: 0.35))
                        .frame(height: 4)
                        .padding(.horizontal, 2)
                )
            Text("\(Int(viewModel.intensity * 100))%")
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.7))
        }
    }

    private var statusRow: some View {
        HStack {
            Image(systemName: viewModel.isSending ? "wifi.exclamationmark" : "checkmark.circle")
                .foregroundStyle(viewModel.isSending ? .orange : .green)
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.7))
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

