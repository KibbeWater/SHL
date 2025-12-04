//
//  GameExtensions.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 27/9/24.
//

import Foundation
import MapKit
import SwiftUI
import UIKit

func getCodeColor(teamKey: String, callback: @escaping (Color) -> Void) {
    if let teamColor = UIImage(named: teamKey) {
        if let cache = ColorCache.shared.getColor(forKey: teamKey) {
            callback(Color(uiColor: cache))
        } else {
            teamColor.getColors(quality: .low) { clr in
                if let _bg = clr?.background {
                    ColorCache.shared.cacheColor(_bg, forKey: teamKey)
                    callback(Color(uiColor: _bg))
                }
            }
        }
    }
}

extension Team {
    func getTeamColor(callback: @escaping (Color) -> Void) {
        let teamKey = "Team/\(self.code.uppercased())"

        getCodeColor(teamKey: teamKey, callback: callback)
    }
}

// Extensions for new API models - only for main app, not widget
#if !WIDGET_EXTENSION
extension TeamBasic {
    func getTeamColor(callback: @escaping (Color) -> Void) {
        let teamKey = "Team/\(self.code.uppercased())"

        getCodeColor(teamKey: teamKey, callback: callback)
    }
}

extension TeamDetail {
    func getTeamColor(callback: @escaping (Color) -> Void) {
        let teamKey = "Team/\(self.code.uppercased())"

        getCodeColor(teamKey: teamKey, callback: callback)
    }
}

extension Player {
    static func fakeData() -> Player {
        return Player(
            id: "8cf03a3a-296e-40b4-8c9d-dde8e0fcd37a",
            externalUUID: "qZl-6LwDhnPuz",
            firstName: "Colby",
            lastName: "Sissons",
            fullName: "Colby Sissons",
            birthDate: nil,
            nationality: .canada,
            position: .forward,
            jerseyNumber: 82,
            height: nil,
            weight: nil,
            teamID: "1c2c3407-6760-4d72-be3c-4cb32661778c",
            team: nil,
            portraitURL: "https://s8y-cdn-sp-photos.imgix.net/https%3A%2F%2Fcdn.ramses.nu%2Fsports%2Fplayer%2Fportrait%2F7767a47a-26fb-4537-aa37-e2bf2ed92611Colby%20Sissons.png?ixlib=js-3.8.0&s=4ece74ce5f42634405015828fa45899b"
        )
    }
}

extension Match {
    func formatDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: date)
    }

    func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    func findVenue(_ cgSize: CGSize, completion: @escaping (Result<(MKMapSnapshotter.Snapshot, CLLocation), Error>) -> Void) {
        guard let venueStr = venue else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(venueStr)"

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let venue = response.mapItems.first {
                let options: MKMapSnapshotter.Options = .init()
                options.region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: venue.placemark.coordinate.latitude,
                        longitude: venue.placemark.coordinate.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                )

                options.size = cgSize
                options.mapType = .hybrid
                options.showsBuildings = true

                let snapshotter = MKMapSnapshotter(
                    options: options
                )

                snapshotter.start { snapshot, error in
                    let location = CLLocation(latitude: venue.placemark.coordinate.latitude, longitude: venue.placemark.coordinate.longitude)
                    if let snapshot = snapshot {
                        completion(.success((snapshot, location)))
                    } else if let _error = error {
                        completion(.failure(_error))
                    }
                }
            }
        }
    }
}
#endif
