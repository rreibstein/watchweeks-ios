import SwiftUI
import UIKit
import WatchWeeksCore

enum WatchWeeksStyle {
    static let paper = adaptive(0xF8F5EF, 0x1D1916)
    static let card = adaptive(0xFFFFFF, 0x28231F)
    static let ink = adaptive(0x191412, 0xF8F3ED)
    static let secondary = adaptive(0x514942, 0xD1C3B7)
    static let border = adaptive(0xD5D0C7, 0x554B43)
    static let control = adaptive(0xEBE7E0, 0x352D27)
    static let link = adaptive(0xA52D1B, 0xFF9F89)
    static let release = adaptive(0x6A3CB0, 0xC9A8FF)

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
}

extension View {
    func watchCard(radius: CGFloat = 16) -> some View {
        background(WatchWeeksStyle.card, in: RoundedRectangle(cornerRadius: radius))
            .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(WatchWeeksStyle.border).allowsHitTesting(false) }
    }

    func watchPage() -> some View {
        foregroundStyle(WatchWeeksStyle.ink).background(WatchWeeksStyle.paper.ignoresSafeArea())
    }
}

struct WatchHeader: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { WatchWordmark(); Spacer(minLength: 4); WatchFindButton(); AccountButton() }
            VStack(alignment: .leading, spacing: 8) {
                WatchWordmark()
                HStack { WatchFindButton(); AccountButton() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(WatchWeeksStyle.paper)
    }
}

struct WatchWordmark: View {
    var compact = false
    var body: some View {
        Text("WatchWeeks").font(compact ? .wwHeadline : .wwTitle2).lineLimit(1)
    }
}

struct WatchFindButton: View {
    var compact = false
    @State private var finding = false
    @State private var pending: WatchDestination?
    @State private var destination: WatchDestination?

    var body: some View {
        Button { finding = true } label: {
            if compact {
                Image(systemName: "magnifyingglass").frame(minWidth: 44, minHeight: 44)
            } else {
                Label("Find", systemImage: "magnifyingglass")
                    .font(.wwSubheadline).padding(.horizontal, 12).frame(minHeight: 44).watchCard(radius: 24)
            }
        }.buttonStyle(.plain).accessibilityLabel("Find")
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

    @ViewBuilder var screen: some View {
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
                        let events = guide.events.filter { matches($0.name) }
                        let brands = guide.brands.filter { matches($0.name) }
                        let releases = guide.releases.filter { matches($0.title) || matches($0.brandName ?? "") }
                        let dealers = (guide.dealers ?? []).filter { matches($0.name) }
                        if matches(guide.city) || !events.isEmpty || !brands.isEmpty || !releases.isEmpty || !dealers.isEmpty {
                            Section(guide.city) {
                                if matches(guide.city) {
                                    Button("Open the \(guide.city) guide") { select(.guide(guide)) }
                                }
                                ForEach(events) { event in Button(event.name) { select(.event(guide, event)) } }
                                ForEach(brands) { brand in Button(brand.name) { select(.brand(guide, brand)) } }
                                ForEach(dealers) { dealer in
                                    if let event = guide.events.first(where: { $0.id == dealer.eventId }) {
                                        Button(dealer.name) { select(.event(guide, event)) }
                                    }
                                }
                                ForEach(releases) { release in Button(release.title) { select(.release(guide, release)) } }
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
