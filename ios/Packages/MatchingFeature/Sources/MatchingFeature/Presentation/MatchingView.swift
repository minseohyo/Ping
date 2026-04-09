import SwiftUI

public struct MatchingView: View {
    @ObservedObject private var viewModel: MatchingViewModel

    public init(viewModel: MatchingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("Ping")
                .font(.largeTitle.bold())

            Button {
                viewModel.ping()
            } label: {
                Text("Ping")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)

            statusText
                .foregroundStyle(.secondary)
        }
        .padding()
        .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private var statusText: some View {
        switch viewModel.state {
        case .idle:
            Text("버튼을 눌러 매칭을 시작하세요.")
        case .connecting:
            Text("전송 중…")
        case .queued:
            Text("대기 중…")
        case .error(let msg):
            Text(msg)
        }
    }
}

