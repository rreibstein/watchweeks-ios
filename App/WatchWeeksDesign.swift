import SwiftUI
import UIKit
import WatchWeeksCore

enum WatchWeeksStyle {
    static let paper = adaptive(0xF8F5EF, 0x1D1916)
    static let card = adaptive(0xFFFFFF, 0x28231F)
    static let seenCard = adaptive(0xEFEFEB, 0x323232)
    static let ink = adaptive(0x191412, 0xF8F3ED)
    static let secondary = adaptive(0x514942, 0xD1C3B7)
    static let border = adaptive(0xD5D0C7, 0x554B43)
    static let control = adaptive(0xEBE7E0, 0x352D27)
    static let link = adaptive(0xA52D1B, 0xFF9F89)
    static let release = adaptive(0x6A3CB0, 0xC9A8FF)
    static let live = Color(rgb: 0x15803D)
    static let today = Color(rgb: 0xB45309)
    static let quiet = Color(rgb: 0x71717A)

    static func city(_ guide: Guide) -> Color {
        switch guide.city.lowercased() {
        case "singapore": Color(rgb: 0xE35335)
        case "hong kong": Color(rgb: 0xA82D7C)
        case "miami": Color(rgb: 0x2EA884)
        case "austin": Color(rgb: 0xC8621E)
        case "new york": Color(rgb: 0x2C5FB8)
        default: release
        }
    }

    static func rating(_ interest: Interest) -> Color {
        switch interest {
        case .mustSee: Color(rgb: 0x7C3AED)
        case .interested: Color(rgb: 0x4F46E5)
        case .little: Color(rgb: 0x475569)
        case .unfamiliar: Color(rgb: 0x64748B)
        case .skip: quiet
        case .none: .clear
        }
    }

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
}

private extension Color {
    init(rgb: UInt32) {
        self.init(red: Double((rgb >> 16) & 255) / 255,
                  green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255)
    }
}

extension View {
    func watchCard(radius: CGFloat = 16, accent: Color? = nil, stripeWidth: CGFloat = 0,
                   fill: Color = WatchWeeksStyle.card) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius)
        return background(fill, in: shape)
            .overlay { shape.strokeBorder(WatchWeeksStyle.border).allowsHitTesting(false) }
            .overlay {
                if let accent {
                    shape.fill(accent).mask(alignment: .leading) { Rectangle().frame(width: stripeWidth) }
                        .allowsHitTesting(false)
                }
            }
    }

    func watchPage() -> some View {
        foregroundStyle(WatchWeeksStyle.ink).background(WatchWeeksStyle.paper.ignoresSafeArea())
    }
}

struct WatchHeader: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                WatchWordmark()
                Spacer(minLength: 4)
                WatchFindButton()
            }
            VStack(alignment: .leading, spacing: 8) {
                WatchWordmark()
                WatchFindButton().frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct WatchWordmark: View {
    @ScaledMetric(relativeTo: .headline) private var markSize = 28.0

    var body: some View {
        HStack(spacing: 6) {
            Image("WatchWeeksMark")
                .resizable()
                .scaledToFit()
                .frame(width: markSize, height: markSize)
                .accessibilityHidden(true)
            Text("WatchWeeks").font(.wwTitle2)
        }
    }
}

private struct WatchFindButton: View {
    @State private var finding = false

    var body: some View {
        Button { finding = true } label: {
            Label("Find", systemImage: "magnifyingglass")
                .font(.wwSubheadline).padding(.horizontal, 12).frame(minHeight: 44).watchCard(radius: 24)
        }.buttonStyle(.plain)
            .modifier(WatchFindPresentation(finding: $finding))
    }
}

extension View {
    func watchFindToolbar() -> some View { modifier(WatchFindToolbar()) }
}

private struct WatchFindToolbar: ViewModifier {
    @State private var finding = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { finding = true } label: {
                        Label("Find", systemImage: "magnifyingglass").labelStyle(.iconOnly)
                    }
                }
            }
            .modifier(WatchFindPresentation(finding: $finding))
    }
}

private struct WatchFindPresentation: ViewModifier {
    @Binding var finding: Bool
    @State private var pending: WatchDestination?
    @State private var destination: WatchDestination?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $finding, onDismiss: {
                destination = pending
                pending = nil
            }) {
                FindView { match in
                    pending = match
                    finding = false
                }
            }
            .navigationDestination(item: $destination) { match in match.screen }
    }
}

private enum WatchDestination: Hashable {
    case guide(Guide)
    case event(Guide, Event)
    case brand(Guide, Brand)
    case release(Guide, Release)

    private var key: [String] {
        switch self {
        case .guide(let guide): ["guide", guide.id]
        case .event(let guide, let item): ["event", guide.id, item.id]
        case .brand(let guide, let item): ["brand", guide.id, item.id]
        case .release(let guide, let item): ["release", guide.id, item.id]
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.key == rhs.key }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }

    @MainActor @ViewBuilder var screen: some View {
        switch self {
        case .guide(let guide): CityView(guide: guide)
        case .event(let guide, let event): EventInfo(guide: guide, event: event)
        case .brand(let guide, let brand): BrandInfo(guide: guide, brand: brand)
        case .release(let guide, let release): ReleaseDetail(guide: guide, release: release)
        }
    }
}

private struct FindView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let select: (WatchDestination) -> Void

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Search cities, events, brands, dealers and new releases.").foregroundStyle(.secondary)
                } else {
                    ForEach(model.guides) { guide in
                        let events = guide.publicEvents.filter { matches($0.name) }
                        let brands = guide.brands.filter { matches($0.displayName) || matches($0.name) }
                        let releases = guide.newReleases.filter {
                            !$0.isTeaser && $0.displayBrandName != nil && matches($0.title)
                        }
                        let dealers = (guide.dealers ?? []).filter { matches($0.name) }
                        if matches(guide.city) || !events.isEmpty || !brands.isEmpty || !releases.isEmpty || !dealers.isEmpty {
                            Section(guide.city) {
                                if matches(guide.city) {
                                    Button("Open the \(guide.city) guide") { select(.guide(guide)) }
                                }
                                ForEach(events) { event in Button(event.name) { select(.event(guide, event)) } }
                                ForEach(brands) { brand in
                                    Button { select(.brand(guide, brand)) } label: {
                                        VStack(alignment: .leading) {
                                            Text(brand.displayName).font(.wwHeadline)
                                            Text(guide.events.filter { brand.eventIDs.contains($0.id) }.map(\.name).joined(separator: " · "))
                                                .font(.wwCaption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                ForEach(dealers) { dealer in
                                    if let event = guide.events.first(where: { $0.id == dealer.eventId }) {
                                        Button(dealer.name) { select(.event(guide, event)) }
                                    }
                                }
                                ForEach(releases) { release in
                                    if let brand = release.displayBrandName {
                                        Button { select(.release(guide, release)) } label: {
                                            VStack(alignment: .leading) {
                                                Text("\(brand) — \(release.title)").font(.wwHeadline)
                                                if let event = guide.events.first(where: { $0.id == release.eventID }) {
                                                    Text(event.name).font(.wwCaption).foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .watchPage()
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Brand, city, event or dealer")
            .navigationTitle("Find")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func matches(_ name: String) -> Bool {
        name.localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct WatchSegments<Value: Hashable>: View {
    @Binding var selection: Value
    let choices: [Value]
    var columns: Int? = nil
    let label: (Value) -> String

    var body: some View {
        Group {
            if let columns {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns), spacing: 4) {
                    ForEach(choices, id: \.self, content: segment)
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 4) { ForEach(choices, id: \.self, content: segment) }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) { ForEach(choices, id: \.self, content: segment) }
                    }
                }
            }
        }
        .padding(4)
        .background(WatchWeeksStyle.control, in: RoundedRectangle(cornerRadius: 16))
    }

    private func segment(_ value: Value) -> some View {
        Button { selection = value } label: {
            Text(label(value)).font(.wwSubheadline.weight(.semibold))
                .fixedSize(horizontal: columns == nil, vertical: true)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(selection == value ? WatchWeeksStyle.card : Color.clear, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
            .accessibilityAddTraits(selection == value ? .isSelected : [])
    }
}

struct WatchDropdown<Value: Hashable, Trigger: View>: View {
    let choices: [Value]
    var selection: Value? = nil
    let title: (Value) -> String
    let select: (Value) -> Void
    @ViewBuilder let label: () -> Trigger
    @State private var showing = false

    var body: some View {
        Button { showing = true } label: { label().font(.wwSubheadline) }
            .buttonStyle(.plain)
            .popover(isPresented: $showing) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(choices, id: \.self) { choice in
                            let selected = selection == choice
                            Button {
                                showing = false
                                select(choice)
                            } label: {
                                HStack(spacing: 8) {
                                    Text(title(choice)).multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                    if selected { Image(systemName: "checkmark").accessibilityHidden(true) }
                                }
                                .frame(minHeight: 44)
                                .padding(.horizontal, 10)
                                .contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }.padding(6)
                }
                .frame(width: 270, height: min(340, CGFloat(choices.count) * 44 + 12))
                .font(.wwSubheadline)
                .foregroundStyle(WatchWeeksStyle.ink)
                .presentationCompactAdaptation(.popover)
            }
    }
}

struct WatchDropdownLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Text(title).multilineTextAlignment(.leading)
            Image(systemName: "chevron.up.chevron.down").font(.wwCaption2).accessibilityHidden(true)
        }.frame(minHeight: 44).contentShape(Rectangle())
    }
}
