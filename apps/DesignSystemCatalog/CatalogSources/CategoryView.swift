import DesignSystem
import SwiftUI

struct CategoryView: View {
  let category: CatalogCategory
  var body: some View {
    Screen(title: category.title) {
      switch category {
      case .colors:
        ColorsDetailView()
      case .typography:
        TypographyDetailView()
      case .gradients:
        GradientsDetailView()
      case .spacing:
        SpacingDetailView()
      case .radius:
        RadiusDetailView()
      case .stroke:
        StrokeDetailView()
      case .elevation:
        ElevationDetailView()
      case .motion:
        MotionDetailView()
      }
    }
    .tint(.ds.primary)
  }
}

private struct Screen<Content: View>: View {
  let title: String
  @ViewBuilder var content: Content

  var body: some View {
    ScrollView {
      contentStack
    }
    .background(Color.ds.background.ignoresSafeArea())
    .navigationTitle(title)
  }

  private var contentStack: some View {
    VStack(alignment: .leading, spacing: .ds.spacing.lg) {
      content
    }
    .padding(.ds.spacing.md)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SectionBlock<Content: View>: View {
  let title: String
  let subtitle: String?
  @ViewBuilder var content: Content

  init(
    _ title: String,
    subtitle: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.subtitle = subtitle
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: .ds.spacing.sm) {
      VStack(alignment: .leading, spacing: .ds.spacing.xxs) {
        Text(title)
          .font(.ds.headline)
          .foregroundStyle(Color.ds.textPrimary)

        if let subtitle {
          Text(subtitle)
            .font(.ds.footnote)
            .foregroundStyle(Color.ds.textSecondary)
        }
      }

      VStack(alignment: .leading, spacing: .ds.spacing.sm) {
        content
      }
      .padding(.ds.spacing.md)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.ds.surface, in: RoundedRectangle(cornerRadius: .ds.radius.lg))
      .overlay(
        RoundedRectangle(cornerRadius: .ds.radius.lg)
          .stroke(Color.ds.separator, lineWidth: .ds.stroke.hairline)
      )
    }
  }
}

private struct ColorSwatch: View {
  let title: String
  let color: Color
  let foreground: Color?

  var body: some View {
    VStack(alignment: .leading, spacing: .ds.spacing.xs) {
      RoundedRectangle(cornerRadius: .ds.radius.md)
        .fill(color)
        .frame(height: 64)
        .overlay {
          if let foreground {
            Text(title)
              .font(.ds.callout)
              .foregroundStyle(foreground)
          }
        }

      if foreground == nil {
        Text(title)
          .font(.ds.caption)
          .foregroundStyle(Color.ds.textSecondary)
      }
    }
    .catalogTVFocusable()
  }
}

private struct TokenRow<Preview: View>: View {
  let name: String
  let value: String
  @ViewBuilder var preview: Preview

  var body: some View {
    VStack(alignment: .leading, spacing: .ds.spacing.xs) {
      HStack(alignment: .firstTextBaseline) {
        Text(name)
          .font(.ds.body)
          .foregroundStyle(Color.ds.textPrimary)
        Spacer()
        Text(value)
          .font(.ds.footnote)
          .foregroundStyle(Color.ds.textSecondary)
      }

      preview
    }
    .catalogTVFocusable()
  }
}

private struct PrimaryColorPicker: View {
  private struct Preset: Identifiable {
    let name: String
    let color: Color
    let foreground: Color

    var id: String { name }
  }

  @State private var selectedPrimary = Colors.shared.primary
  private let presets: [Preset] = [
    .init(name: "Blue", color: .blue, foreground: .white),
    .init(name: "Indigo", color: .indigo, foreground: .white),
    .init(name: "Pink", color: .pink, foreground: .white),
    .init(name: "Orange", color: .orange, foreground: .black),
    .init(name: "Green", color: .green, foreground: .black),
    .init(name: "Yellow", color: .yellow, foreground: .black)
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: .ds.spacing.sm) {
      primaryInput

      VStack(alignment: .leading, spacing: .ds.spacing.sm) {
        Text("On-primary preview")
          .font(.ds.caption)
          .foregroundStyle(Color.ds.textSecondary)

        RoundedRectangle(cornerRadius: .ds.radius.md)
          .fill(Color.ds.primary)
          .frame(height: 56)
          .overlay {
            Text("Primary action")
              .font(.ds.callout)
              .foregroundStyle(Color.ds.onPrimary)
          }

        Button("Tint Sample") {}
          .foregroundStyle(Color.ds.onPrimary)
          .buttonStyle(.borderedProminent)
      }
    }
    .onAppear {
      selectedPrimary = Colors.shared.primary
    }
    .onChange(of: selectedPrimary) { _, newValue in
      Colors.shared.primary = newValue
    }
  }

  @ViewBuilder
  private var primaryInput: some View {
    #if os(watchOS) || os(tvOS)
      VStack(alignment: .leading, spacing: .ds.spacing.sm) {
        Text("Primary presets")
          .font(.ds.caption)
          .foregroundStyle(Color.ds.textSecondary)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: .ds.spacing.sm)]) {
          ForEach(presets) { preset in
            Button(preset.name) {
              selectedPrimary = preset.color
            }
            .buttonStyle(.plain)
            .font(.ds.footnote)
            .foregroundStyle(preset.foreground)
            .padding(.horizontal, .ds.spacing.sm)
            .padding(.vertical, .ds.spacing.xs)
            .frame(maxWidth: .infinity)
            .background(preset.color, in: Capsule())
            .overlay {
              Capsule()
                .strokeBorder(
                  selectedPrimary == preset.color ? Color.ds.textPrimary : .clear,
                  lineWidth: .ds.stroke.regular
                )
            }
          }
        }
      }
    #else
      ColorPicker("Primary color", selection: $selectedPrimary, supportsOpacity: false)
    #endif
  }
}

private struct ColorsDetailView: View {
  private var semanticColors: [(String, Color)] {
    [
      ("Success", .ds.success),
      ("Warning", .ds.warning),
      ("Danger", .ds.danger),
      ("Info", .ds.info),
      ("Background", .ds.background),
      ("Surface", .ds.surface),
      ("Surface Elevated", .ds.surfaceElevated),
      ("Separator", .ds.separator),
      ("Text Primary", .ds.textPrimary),
      ("Text Secondary", .ds.textSecondary),
      ("Text Tertiary", .ds.textTertiary),
      ("Link", .ds.link),
      ("Disabled", .ds.disabled),
      ("Placeholder", .ds.placeholder)
    ]
  }

  private var rawColors: [(String, Color)] {
    [
      ("Red", .ds.raw.red),
      ("Orange", .ds.raw.orange),
      ("Yellow", .ds.raw.yellow),
      ("Green", .ds.raw.green),
      ("Mint", .ds.raw.mint),
      ("Teal", .ds.raw.teal),
      ("Cyan", .ds.raw.cyan),
      ("Blue", .ds.raw.blue),
      ("Indigo", .ds.raw.indigo),
      ("Purple", .ds.raw.purple),
      ("Pink", .ds.raw.pink),
      ("Brown", .ds.raw.brown),
      ("Gray", .ds.raw.gray),
      ("Black", .ds.raw.black)
    ]
  }

  var body: some View {
    Group {
      SectionBlock(
        "Primary Preview",
        subtitle: "Pick any primary color and confirm on-primary contrast and tint updates."
      ) {
        PrimaryColorPicker()
      }

      SectionBlock(
        "Primary",
        subtitle: "Primary is dynamic and paired with a readable on-primary foreground."
      ) {
        VStack(alignment: .leading, spacing: .ds.spacing.md) {
          RoundedRectangle(cornerRadius: .ds.radius.md)
            .fill(Color.ds.primary)
            .frame(height: 88)
            .overlay(alignment: .leading) {
              VStack(alignment: .leading, spacing: .ds.spacing.xxs) {
                Text("Tinted Card")
                  .font(.ds.headline)
                Text("Use on-primary for content on primary backgrounds.")
                  .font(.ds.footnote)
              }
              .foregroundStyle(Color.ds.onPrimary)
              .padding(.horizontal, .ds.spacing.md)
            }

          HStack(spacing: .ds.spacing.sm) {
            Button("Primary Action") {}
              .foregroundStyle(Color.ds.onPrimary)
              .buttonStyle(.borderedProminent)

            Label("42", systemImage: "star.fill")
              .font(.ds.callout)
              .foregroundStyle(Color.ds.onPrimary)
              .padding(.horizontal, .ds.spacing.sm)
              .padding(.vertical, .ds.spacing.xs)
              .background(Color.ds.primary, in: Capsule())
          }
        }
      }

      SectionBlock(
        "Semantic",
        subtitle: "Use these by meaning instead of hard-coded palette values."
      ) {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: .ds.spacing.md) {
          ForEach(Array(semanticColors.enumerated()), id: \.offset) { _, item in
            ColorSwatch(title: item.0, color: item.1, foreground: nil)
          }
        }
      }

      SectionBlock(
        "Raw Palette",
        subtitle: "Decorative colors intentionally separated behind .ds.raw."
      ) {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: .ds.spacing.md) {
          ForEach(Array(rawColors.enumerated()), id: \.offset) { _, item in
            ColorSwatch(title: item.0, color: item.1, foreground: nil)
          }
        }
      }
    }
  }

  private var gridColumns: [GridItem] {
    [
      GridItem(.adaptive(minimum: 120), spacing: .ds.spacing.md)
    ]
  }
}

private struct TypographyDetailView: View {
  private let samples: [(String, Font)] = [
    ("Large Title", .ds.largeTitle),
    ("Title", .ds.title),
    ("Title 2", .ds.title2),
    ("Title 3", .ds.title3),
    ("Headline", .ds.headline),
    ("Body", .ds.body),
    ("Callout", .ds.callout),
    ("Subheadline", .ds.subheadline),
    ("Footnote", .ds.footnote),
    ("Caption", .ds.caption),
    ("Caption 2", .ds.caption2)
  ]

  var body: some View {
    SectionBlock(
      "Type Scale",
      subtitle: "Every sample uses native text styles from design-system tokens."
    ) {
      ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
        VStack(alignment: .leading, spacing: .ds.spacing.xxs) {
          Text(sample.0)
            .font(.ds.caption)
            .foregroundStyle(Color.ds.textSecondary)

          Text("Design System Catalog")
            .font(sample.1)
            .foregroundStyle(Color.ds.textPrimary)
        }
        .catalogTVFocusable()

        if sample.0 != samples.last?.0 {
          Divider()
        }
      }
    }
  }
}

private extension View {
  @ViewBuilder
  func catalogTVFocusable() -> some View {
    #if os(tvOS)
      focusable()
    #else
      self
    #endif
  }
}

private struct GradientsDetailView: View {
  private var intelligenceGradient: LinearGradient {
    LinearGradient(
      gradient: .ds.intelligence,
      startPoint: .leading,
      endPoint: .trailing
    )
  }

  var body: some View {
    Group {
      SectionBlock(
        "Intelligence",
        subtitle: "Decorative shared gradient inspired by Apple Intelligence."
      ) {
        RoundedRectangle(cornerRadius: .ds.radius.xl)
          .fill(intelligenceGradient)
          .frame(height: 180)
          .overlay {
            Text("Intelligence")
              .font(.ds.title)
              .foregroundStyle(.white)
          }
      }

      SectionBlock(
        "Foreground Sample",
        subtitle: "Use gradients sparingly for display text and decorative accents."
      ) {
        Text("Apple-style expressive color")
          .font(.ds.largeTitle)
          .foregroundStyle(intelligenceGradient)
      }
    }
  }
}

private struct SpacingDetailView: View {
  private let samples: [(String, CGFloat)] = [
    ("XXS", .ds.spacing.xxs),
    ("XS", .ds.spacing.xs),
    ("SM", .ds.spacing.sm),
    ("MD", .ds.spacing.md),
    ("LG", .ds.spacing.lg),
    ("XL", .ds.spacing.xl),
    ("XXL", .ds.spacing.xxl)
  ]

  var body: some View {
    SectionBlock(
      "Spacing Scale",
      subtitle: "Capsule widths scale with token values."
    ) {
      ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
        TokenRow(name: sample.0, value: "\(Int(sample.1)) pt") {
          Capsule()
            .fill(Color.ds.primary)
            .frame(width: max(sample.1 * 6, 24), height: 10)
        }
      }
    }
  }
}

private struct RadiusDetailView: View {
  private let samples: [(String, CGFloat)] = [
    ("Small", .ds.radius.sm),
    ("Medium", .ds.radius.md),
    ("Large", .ds.radius.lg),
    ("Extra Large", .ds.radius.xl),
    ("Full", .ds.radius.full)
  ]

  var body: some View {
    SectionBlock(
      "Corner Radius",
      subtitle: "Container treatment becomes softer as radius increases."
    ) {
      ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
        TokenRow(
          name: sample.0,
          value: sample.0 == "Full" ? "Capsule" : "\(Int(sample.1)) pt"
        ) {
          RoundedRectangle(cornerRadius: sample.1)
            .fill(Color.ds.surfaceElevated)
            .frame(height: 60)
            .overlay(
              RoundedRectangle(cornerRadius: sample.1)
                .stroke(Color.ds.separator, lineWidth: .ds.stroke.hairline)
            )
        }
      }
    }
  }
}

private struct StrokeDetailView: View {
  private let samples: [(String, CGFloat)] = [
    ("Hairline", .ds.stroke.hairline),
    ("Thin", .ds.stroke.thin),
    ("Regular", .ds.stroke.regular),
    ("Thick", .ds.stroke.thick)
  ]

  var body: some View {
    SectionBlock(
      "Stroke Widths",
      subtitle: "Outline thickness for separators and emphasis."
    ) {
      ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
        TokenRow(name: sample.0, value: "\(oneDecimal(sample.1)) pt") {
          RoundedRectangle(cornerRadius: .ds.radius.md)
            .stroke(Color.ds.primary, lineWidth: sample.1)
            .frame(height: 52)
        }
      }
    }
  }
}

private struct ElevationDetailView: View {
  private let samples: [(String, Shadow)] = [
    ("Flat", .ds.flat),
    ("Raised", .ds.raised),
    ("Floating", .ds.floating)
  ]

  var body: some View {
    SectionBlock(
      "Elevation",
      subtitle: "Shadows are decorative and should never carry meaning alone."
    ) {
      ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
        TokenRow(name: sample.0, value: shadowDescription(sample.1)) {
          RoundedRectangle(cornerRadius: .ds.radius.lg)
            .fill(Color.ds.surfaceElevated)
            .frame(height: 72)
            .overlay(alignment: .leading) {
              Text(sample.0)
                .font(.ds.callout)
                .foregroundStyle(Color.ds.textPrimary)
                .padding(.horizontal, .ds.spacing.md)
            }
            .shadow(sample.1)
        }
      }
    }
  }

  private func shadowDescription(_ shadow: Shadow) -> String {
    if shadow.radius == .zero && shadow.x == .zero && shadow.y == .zero {
      return "No shadow"
    }
    return "r \(Int(shadow.radius)), x \(Int(shadow.x)), y \(Int(shadow.y))"
  }
}

private struct MotionDetailView: View {
  private let samples: [(String, Double, Color)] = [
    ("Quick", .ds.motion.quick, .ds.info),
    ("Standard", .ds.motion.standard, .ds.primary),
    ("Emphasis", .ds.motion.emphasis, .ds.warning)
  ]
  @State private var replayID = 0

  var body: some View {
    Group {
      SectionBlock(
        "Timing Playground",
        subtitle: "Replay all samples together to compare token timing by feel."
      ) {
        Button("Replay Animation") {
          replayID += 1
        }
        .buttonStyle(.borderedProminent)

        ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
          MotionTimingRow(
            name: sample.0,
            duration: sample.1,
            color: sample.2,
            replayID: replayID
          )
        }
      }

      SectionBlock(
        "Motion Tokens",
        subtitle: "Reference values used by the timing playground."
      ) {
        ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
          TokenRow(name: sample.0, value: "\(twoDecimals(sample.1)) s") {
            Capsule()
              .fill(sample.2)
              .frame(width: CGFloat(sample.1 * 320), height: 12)
          }
        }
      }
    }
  }
}

private struct MotionTimingRow: View {
  let name: String
  let duration: Double
  let color: Color
  let replayID: Int
  @State private var progress = 0.0

  var body: some View {
    TokenRow(name: name, value: "\(twoDecimals(duration)) s") {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(Color.ds.surfaceElevated)
            .frame(height: 14)

          Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .offset(x: progress * max(geometry.size.width - 24, 0))
            .shadow(.ds.raised)
        }
      }
      .frame(height: 24)
      .onAppear {
        runAnimation()
      }
      .onChange(of: replayID) { _, _ in
        runAnimation()
      }
    }
  }

  private func runAnimation() {
    progress = 0

    withAnimation(.easeInOut(duration: duration)) {
      progress = 1
    }
  }
}

private func oneDecimal(_ value: CGFloat) -> String {
  let rounded = (value * 10).rounded() / 10
  return "\(rounded)"
}

private func twoDecimals(_ value: Double) -> String {
  let rounded = (value * 100).rounded() / 100
  return "\(rounded)"
}
