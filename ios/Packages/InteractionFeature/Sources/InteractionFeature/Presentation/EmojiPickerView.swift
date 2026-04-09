import SwiftUI

public struct EmojiPickerView: View {
    private let onSelect: (String) -> Void
    private let emojis: [(id: String, label: String)]

    public init(emojis: [(String, String)] = [("thumbs_up","👍"), ("heart","❤️"), ("laugh","😂")],
                onSelect: @escaping (String) -> Void) {
        self.emojis = emojis
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("이모티콘 보내기")
                .font(.headline)
            HStack(spacing: 18) {
                ForEach(emojis, id: \.id) { item in
                    Button {
                        onSelect(item.id)
                    } label: {
                        Text(item.label)
                            .font(.system(size: 36))
                            .frame(width: 56, height: 56)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .presentationDetents([.height(180)])
    }
}

