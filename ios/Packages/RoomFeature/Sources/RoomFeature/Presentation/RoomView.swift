import SwiftUI
import CoreModels
import CoreUI

public struct RoomView: View {
    @ObservedObject private var viewModel: RoomViewModel
    private let onMemberSelected: (Member) -> Void

    public init(viewModel: RoomViewModel, onMemberSelected: @escaping (Member) -> Void) {
        self.viewModel = viewModel
        self.onMemberSelected = onMemberSelected
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(viewModel.members) { m in
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            AvatarView(member: m)
                                .frame(width: 88, height: 88)

                            if let emojiId = viewModel.floatingEmojiByUserId[m.userId] {
                                Text(renderEmoji(emojiId))
                                    .font(.system(size: 28))
                                    .padding(6)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        Text(m.nickname)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onMemberSelected(m) }
                }
            }
            .padding()
        }
        .navigationTitle("Room")
        .onAppear { viewModel.onAppear() }
    }

    private func renderEmoji(_ emojiId: String) -> String {
        switch emojiId {
        case "thumbs_up": return "👍"
        case "heart": return "❤️"
        case "laugh": return "😂"
        default: return "✨"
        }
    }
}

