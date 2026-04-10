import SwiftUI

public struct AuthView: View {
    @ObservedObject private var viewModel: AuthViewModel
    private let onAuthenticated: (Me) -> Void

    public init(viewModel: AuthViewModel, onAuthenticated: @escaping (Me) -> Void) {
        self.viewModel = viewModel
        self.onAuthenticated = onAuthenticated
    }

    public var body: some View {
        content
            .onAppear { viewModel.onAppear() }
            .onChange(of: viewModel.state) { new in
                if case .authenticated(let me) = new {
                    onAuthenticated(me)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading…")
        case .needsNickname:
            VStack(spacing: 16) {
                Text("닉네임을 입력해주세요")
                    .font(.headline)
                TextField("Nickname", text: $viewModel.nickname)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("계속") {
                    viewModel.submitNickname()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        case .authenticated(let me):
            VStack(spacing: 12) {
                Text("Hello, \(me.nickname)")
                ProgressView()
            }
            .padding()
        case .error(let msg):
            VStack(spacing: 12) {
                Text("Error")
                    .font(.headline)
                Text(msg)
                Button("Retry") {
                    viewModel.onAppear()
                }
            }
            .padding()
        }
    }
}

