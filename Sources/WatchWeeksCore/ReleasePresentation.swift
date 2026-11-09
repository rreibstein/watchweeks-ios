import Foundation

public extension Release {
    var displayBrandName: String? { brandName.map { Brand.canonicalName($0, id: brandID) } }

    var displayImages: [ReleaseImageData] { images.filter(\.isDisplayable) }
    var displaySharedImages: [ReleaseImageData] { (sharedImages ?? []).filter(\.isDisplayable) }

    // The public feed delivers one editorial block per brand/event/kind. Only
    // paragraph-leading model headings can start a new item.
    var individualModels: [Release] {
        guard let details else { return [self] }
        var blocks: [(title: String, text: String)] = []
        for paragraph in details.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n\n") {
            let heading = paragraph.split(separator: "\n").first.map(String.init) ?? ""
            if let separator = heading.range(of: " — "), heading.distance(from: heading.startIndex, to: separator.lowerBound) <= 120 {
                blocks.append((String(heading[..<separator.lowerBound]).trimmingCharacters(in: .whitespaces), paragraph))
            } else if !blocks.isEmpty {
                blocks[blocks.count - 1].text += "\n\n" + paragraph
            }
        }
        guard blocks.count > 1 else { return [self] }

        // Match model tokens in editorial filenames. Keep ambiguous photos
        // at the release-group level.
        let pictured = blocks.indices.filter { blocks[$0].title.caseInsensitiveCompare("Teaser") != .orderedSame }
        var assignments: [Int: [ReleaseImageData]] = [:]
        var shared: [ReleaseImageData] = []
        for image in displayImages {
            let file = image.resolvedURL?.lastPathComponent ?? image.url
            let fileWords = Self.tokens(file)
            let scores = pictured.map { block in (block, Self.tokens(blocks[block].title).intersection(fileWords).count) }
            let best = scores.map(\.1).max() ?? 0
            let matches = scores.filter { $0.1 == best }
            if best >= 2, matches.count == 1 {
                assignments[matches[0].0, default: []].append(image)
            } else {
                shared.append(image)
            }
        }

        return blocks.enumerated().map { index, block in
            let photos = assignments[index, default: []]
            let occurrence = blocks.prefix(index).count { $0.title == block.title }
            return Release(id: "\(id)|model|\(block.title)|\(occurrence)", title: block.title, brandName: brandName,
                           details: block.text, imageURL: photos.first?.resolvedURL, webURL: webURL,
                           brandID: brandID, eventID: eventID, kind: kind, images: photos,
                           sharedImages: index == pictured.first ? shared : nil)
        }
    }

    private static func tokens(_ text: String) -> Set<String> {
        Set(text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 2 })
    }

    var isTeaser: Bool { title.caseInsensitiveCompare("Teaser") == .orderedSame }

    var displayedPrice: String? {
        guard let details else { return nil }
        let pattern = #"(?i)\bPrice:\s*((?:(?:US|AU|CA|HK|SG|S|NZ|C|A)?\$|[€£¥]|(?:CHF|USD|CAD|AUD|SGD|HKD|JPY|EUR|GBP)\s+)\s*\d[\d,.]*(?:\s\d{3})*(?:\s*[–-]\s*[$€£]?\d[\d,.]*)?)"#
        guard let match = details.range(of: pattern, options: .regularExpression) else { return nil }
        let value = details[match].dropFirst(details[match].firstIndex(of: ":").map { details[match].distance(from: match.lowerBound, to: $0) + 1 } ?? 0)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,")))
        return value.replacingOccurrences(of: #"(?i)^US\$\s*|^USD\s+"#, with: "$", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)^(?:SGD\s+|SG\$\s*)"#, with: "S$", options: .regularExpression)
    }

    var isNotExhibited: Bool {
        (details ?? "").range(of: #"(?i)\b(?:not at (?:the )?show|not exhibited at (?:the )?show|will not be (?:shown|exhibited) at (?:the )?show)\b"#,
                                options: .regularExpression) != nil
    }

    var displayBadges: [String] {
        let text = details ?? ""
        var labels: [String] = []
        if text.range(of: #"(?i)\b(?:Availability|Status):\s*Sold out\b"#, options: .regularExpression) != nil {
            labels.append("Sold out")
        }
        if isNotExhibited { labels.append("Not exhibited at show") }
        for kind in ["winner", "nominee"] {
            let phrase = #"(?i)\b(?:2026 GPHG|GPHG 2026)[^.!?\n]{0,65}\b"# + kind + #"\b"#
            if text.range(of: phrase, options: .regularExpression) != nil {
                labels.append("GPHG 2026 \(kind)")
            }
        }
        for award in awards where !award.isEmpty && !labels.contains(where: { $0.caseInsensitiveCompare(award) == .orderedSame }) {
            labels.append(award)
        }
        return labels
    }
}

extension Release {
    // The New York v1 feed omits images. These are the three brand-credited
    // highlights published on the WatchWeeks home page for the 2026 edition.
    var withNewYorkHighlightPhoto: Release {
        guard images.isEmpty, eventID == "windup" else { return self }
        let asset: String
        let credit: String
        switch (brandID, title) {
        case ("bremont", "Supermarine Full Ceramic Deep Blue"):
            asset = "bb2bb298-cae4-4760-bcf5-690b3b26dd37/windup-bremont-supermarine-full-ceramic-deep-blue-2.jpg"
            credit = "Bremont"
        case ("brewwatchco", "Metric Chrono Taxi"):
            asset = "1075c0a9-8cc4-435f-a08b-90e284abc287/windup-brew-nyc-edition-2.png"
            credit = "Brew Watch Co."
        case ("bulova", "A-11 Jimmy"):
            asset = "5b283932-17b1-4b2c-966c-8fdae537c411/windup-bulova-a-11-jimmy-1.jpg"
            credit = "Bulova"
        default: return self
        }
        let photo = ReleaseImageData(url: "/__l5e/assets-v1/" + asset, credit: credit, link: webURL?.absoluteString)
        return Release(id: id, title: title, brandName: brandName, details: details, imageURL: photo.resolvedURL,
                       webURL: webURL, brandID: brandID, eventID: eventID, kind: kind, images: [photo],
                       awards: awards, sharedImages: sharedImages)
    }
}

private extension ReleaseImageData {
    // Editorial source links at the release level can refer to reporting while the
    // photo comes from the brand. Only inspect the individual photo's provenance.
    static var excludedSources: [String] {
        ["monochrome", "hodinkee", "timeandtide", "timetide", "fratello", "oracletime", "oracleoftime",
         "wornandwound", "wornwound", "watchtime", "hautetime", "deployant",
         "watchesofespionage", "watchpro", "ablogtowatch", "hypebeast",
         "revolutionwatch", "robbreport", "watchonista", "watchesbysjx",
         "swisswatchesmagazine", "exquisitetimepieces"]
    }

    var isDisplayable: Bool {
        guard let credit, !credit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = PublicLinks.safeExternal(resolvedURL) else { return false }
        let linkHost = link.flatMap { URL(string: $0)?.host } ?? ""
        let provenance = [credit, linkHost, url.host ?? "", url.lastPathComponent].map {
            $0.lowercased().filter { $0.isLetter || $0.isNumber }
        }
        return !Self.excludedSources.contains { source in provenance.contains { $0.contains(source) } }
    }
}
