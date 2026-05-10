import DesignSystem
import Emojis
import SwiftUI

struct EmojiLibraryView: View {
  private enum Constants {
    static let columnCount = 6
    static let libraryHeight: CGFloat = 316
    static let emojiCellSize: CGFloat = 40
    static let emojiFontSize: CGFloat = 30
    static let categoryButtonSize: CGFloat = 24
    static let bottomContentInset: CGFloat = categoryButtonSize + .ds.spacing.md

    static func gridSpacing(for width: CGFloat) -> CGFloat {
      let occupiedWidth = CGFloat(columnCount) * emojiCellSize
      return max(.zero, (width - occupiedWidth) / CGFloat(columnCount - 1))
    }
  }

  static let preferredHeight = Constants.libraryHeight

  let contentWidth: CGFloat
  let horizontalContentInset: CGFloat
  let topContentInset: CGFloat
  let onSelectEmoji: (String) -> Void

  private static let sections = EmojiLibrarySection.load()

  private var gridWidth: CGFloat {
    max(.zero, contentWidth - (horizontalContentInset * 2))
  }

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(
        .fixed(Constants.emojiCellSize),
        spacing: Constants.gridSpacing(for: gridWidth)
      ),
      count: Constants.columnCount
    )
  }

  init(
    contentWidth: CGFloat = 324,
    horizontalContentInset: CGFloat = .ds.spacing.xs,
    topContentInset: CGFloat = .zero,
    onSelectEmoji: @escaping (String) -> Void
  ) {
    self.contentWidth = contentWidth
    self.horizontalContentInset = horizontalContentInset
    self.topContentInset = topContentInset
    self.onSelectEmoji = onSelectEmoji
  }

  var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .bottom) {
        ScrollView(.vertical, showsIndicators: false) {
          LazyVStack(alignment: .leading, spacing: .ds.spacing.md) {
            ForEach(Self.sections) { section in
              sectionView(section)
                .id(section.id)
            }
          }
          .frame(width: gridWidth, alignment: .leading)
          .padding(.horizontal, horizontalContentInset)
          .padding(.top, topContentInset + .ds.spacing.sm)
          .padding(.bottom, Constants.bottomContentInset)
        }

        categoryBar(proxy: proxy)
          .frame(width: gridWidth)
          .padding(.horizontal, horizontalContentInset)
          .padding(.bottom, .ds.spacing.xxs)
      }
    }
    .frame(width: contentWidth)
    .frame(maxHeight: .infinity)
  }

  private func sectionView(_ section: EmojiLibrarySection) -> some View {
    VStack(alignment: .leading, spacing: .ds.spacing.xs) {
      Text(section.title)
        .font(.ds.caption.weight(.semibold))
        .foregroundStyle(Color.ds.textSecondary)

      LazyVGrid(columns: columns, alignment: .leading, spacing: .ds.spacing.xs) {
        ForEach(section.emojis) { emoji in
          Button {
            onSelectEmoji(emoji.value)
          } label: {
            Text(emoji.value)
              .font(.system(size: Constants.emojiFontSize))
              .frame(width: Constants.emojiCellSize, height: Constants.emojiCellSize)
              .contentShape(RoundedRectangle(cornerRadius: .ds.radius.sm, style: .continuous))
          }
          .buttonStyle(.plain)
          .accessibilityLabel(emoji.accessibilityLabel)
        }
      }
    }
  }

  private func categoryBar(proxy: ScrollViewProxy) -> some View {
    HStack(spacing: .zero) {
      ForEach(Self.sections) { section in
        Button {
          withAnimation(.snappy(duration: .ds.motion.quick)) {
            proxy.scrollTo(section.id, anchor: .top)
          }
        } label: {
          Image(systemName: section.symbolName)
            .font(.ds.caption.weight(.medium))
            .foregroundStyle(Color.ds.textSecondary)
            .frame(width: Constants.categoryButtonSize, height: Constants.categoryButtonSize)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(section.title)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

private struct EmojiLibrarySection: Identifiable {
  let id: String
  let title: LocalizedStringResource
  let symbolName: String
  let emojis: [EmojiLibraryItem]

  static func load() -> [Self] {
    let fetchedEmojis = loadAvailableEmojis()
    let lookup = Dictionary(grouping: fetchedEmojis, by: \.group)
    let groups = EmojiLibraryGroup.all.compactMap { group -> Self? in
      guard let emojis = lookup[group.emojiGroup], !emojis.isEmpty else {
        return nil
      }

      let items =
        emojis
        .sorted { $0.sortOrder < $1.sortOrder }
        .map(EmojiLibraryItem.init(emoji:))

      return Self(
        id: group.id,
        title: group.title,
        symbolName: group.symbolName,
        emojis: items
      )
    }

    return groups
  }

  private static func loadAvailableEmojis() -> [Emoji] {
    let filter: Emojis.Filter

    #if canImport(CoreText)
      filter = .apple
    #else
      filter = .none
    #endif

    let emojis = (try? Emojis.fetch(filter: filter)) ?? []
    return emojis.filter { $0.group != .component }
  }
}

private struct EmojiLibraryItem: Identifiable {
  let id: String
  let value: String
  let accessibilityLabel: String

  nonisolated init(emoji: Emoji) {
    self.id = emoji.id.rawValue
    self.value = emoji.value
    self.accessibilityLabel = emoji.localization.name
  }
}

private struct EmojiLibraryGroup {
  let emojiGroup: Emoji.Group
  let title: LocalizedStringResource
  let symbolName: String

  var id: String { emojiGroup.rawValue }

  static let all = [
    Self(emojiGroup: .smileysEmotion, title: .emojiCategorySmileys, symbolName: "face.smiling"),
    Self(emojiGroup: .peopleBody, title: .emojiCategoryPeople, symbolName: "figure.wave"),
    Self(emojiGroup: .animalsNature, title: .emojiCategoryNature, symbolName: "leaf"),
    Self(emojiGroup: .foodDrink, title: .emojiCategoryFood, symbolName: "fork.knife"),
    Self(emojiGroup: .travelPlaces, title: .emojiCategoryTravel, symbolName: "car"),
    Self(emojiGroup: .activities, title: .emojiCategoryActivities, symbolName: "soccerball"),
    Self(emojiGroup: .objects, title: .emojiCategoryObjects, symbolName: "lightbulb"),
    Self(emojiGroup: .symbols, title: .emojiCategorySymbols, symbolName: "heart"),
    Self(emojiGroup: .flags, title: .emojiCategoryFlags, symbolName: "flag")
  ]
}

#Preview {
  EmojiLibraryView(topContentInset: 60, onSelectEmoji: { _ in })
    .frame(width: 324, height: 376)
}
