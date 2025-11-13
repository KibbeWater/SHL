//
//  TeamLogoView.swift
//  SHL
//
//  Created by Claude Code
//

import Kingfisher
import SVGKit
import SwiftUI

/// A reusable component for displaying team logos with intelligent fallback handling.
///
/// Priority order:
/// 1. Local asset (Team/{code}) - for SVG logos in Assets.xcassets
/// 2. Remote URL (iconURL) - using Kingfisher for PNG/JPG/SVG
/// 3. TBD fallback (Team/TBD) - when team is unknown
struct TeamLogoView: View {
    // MARK: - Properties

    private let teamCode: String
    private let iconURL: String?
    private let size: TeamLogoSize

    // MARK: - Initializers

    /// Initialize with a Team model
    init(team: Team, size: TeamLogoSize = .medium) {
        self.teamCode = team.code.uppercased()
        self.iconURL = team.iconURL
        self.size = size
    }

    /// Initialize with team code only
    init(teamCode: String, size: TeamLogoSize = .medium) {
        self.teamCode = teamCode.uppercased()
        self.iconURL = nil
        self.size = size
    }

    /// Initialize with team code and optional remote URL
    init(teamCode: String, iconURL: String? = nil, size: TeamLogoSize = .medium) {
        self.teamCode = teamCode.uppercased()
        self.iconURL = iconURL
        self.size = size
    }

    // MARK: - Body

    var body: some View {
        Group {
            if hasLocalAsset {
                // Use local asset (SVG from Assets.xcassets)
                Image("Team/\(teamCode)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.dimension, height: size.dimension)
            } else if let urlString = iconURL, let url = URL(string: urlString) {
                // Use remote URL with Kingfisher
                KFImage(url)
                    .onSuccess { _ in
                        // Successfully loaded remote image
                        print("Loaded remote image \(url)")
                    }
                    .onFailure { error in
                        // Failed to load remote image, will show TBD fallback
                        print("Failed to load team logo from \(url): \(error.localizedDescription)")
                    }
                    .placeholder {
                        // Show TBD while loading
                        Image("Team/TBD")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .setProcessor(imageProcessor(for: url))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.dimension, height: size.dimension)
            } else {
                // Fallback to TBD
                Image("Team/TBD")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.dimension, height: size.dimension)
            }
        }
    }

    // MARK: - Private Helpers

    /// Check if local asset exists in the bundle
    private var hasLocalAsset: Bool {
        // Try to load the image from the asset catalog
        let assetName = "Team/\(teamCode)"
        #if os(iOS)
        return UIImage(named: assetName) != nil
        #else
        return NSImage(named: assetName) != nil
        #endif
    }

    /// Determine the appropriate image processor based on URL extension
    private func imageProcessor(for url: URL) -> ImageProcessor {
        let urlString = url.absoluteString.lowercased()

        // Check if it's an SVG
        if urlString.hasSuffix(".svg") {
            // Use custom SVG processor for vector images
            return SVGImgProcessor()
        } else {
            // Use downsampling for raster images (PNG, JPG) to save memory
            return DownsamplingImageProcessor(size: CGSize(width: size.dimension * 2, height: size.dimension * 2))
        }
    }
}

// MARK: - SVG Image Processor

/// Custom Kingfisher processor for handling SVG images
/// Uses SVGKit to parse SVG data and convert to UIImage
struct SVGImgProcessor: ImageProcessor {
    var identifier: String = "com.kibbewater.shl.svgprocessor"

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            // Already processed as an image
            return image
        case .data(let data):
            // Parse SVG data using SVGKit
            if let svgImage = SVGKImage(data: data) {
                return svgImage.uiImage
            }
            return nil
        }
    }
}

// MARK: - Team Logo Size

/// Predefined sizes for team logos based on common usage patterns in the app
enum TeamLogoSize {
    case extraSmall // 22x22 - Used in player info headers
    case small // 32x32 - Used in standings table
    case mediumSmall // 46x46 - Used in player season stats
    case medium // 48x48 - Used in match overviews
    case large // 72x72 - Used in team headers
    case extraLarge // 84x84 - Used in match headers
    case custom(CGFloat)

    var dimension: CGFloat {
        switch self {
        case .extraSmall:
            return 22
        case .small:
            return 32
        case .mediumSmall:
            return 46
        case .medium:
            return 48
        case .large:
            return 72
        case .extraLarge:
            return 84
        case .custom(let size):
            return size
        }
    }
}

// MARK: - Preview

#Preview("Local Asset") {
    VStack(spacing: 20) {
        TeamLogoView(teamCode: "LHF", size: .extraSmall)
        TeamLogoView(teamCode: "LHF", size: .small)
        TeamLogoView(teamCode: "LHF", size: .medium)
        TeamLogoView(teamCode: "LHF", size: .large)
        TeamLogoView(teamCode: "LHF", size: .extraLarge)
    }
    .padding()
}

#Preview("TBD Fallback") {
    VStack(spacing: 20) {
        TeamLogoView(teamCode: "INVALID", size: .medium)
        TeamLogoView(teamCode: "XYZ", size: .large)
    }
    .padding()
}

#Preview("Remote URL") {
    VStack(spacing: 20) {
        TeamLogoView(
            teamCode: "MODO",
            iconURL: "https://sportality.cdn.s8y.se/team-logos/modo1_modo.svg",
            size: .large
        )
    }
    .padding()
}
