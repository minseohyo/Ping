import SwiftUI
import CoreModels

public struct AvatarView: View {
    private let nickname: String

    public init(member: Member) {
        self.nickname = member.nickname
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
            Text(initials(from: nickname))
                .font(.headline)
                .foregroundStyle(.gray)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(Text(nickname))
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if let first = parts.first?.first {
            return String(first).uppercased()
        }
        return "?"
    }
}

