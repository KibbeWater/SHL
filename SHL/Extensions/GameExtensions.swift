//
//  GameExtensions.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 27/9/24.
//

import Foundation
import HockeyKit
import UIKit
import SwiftUI
import MapKit

extension Game {
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
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(venue)"
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
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

extension SiteTeam {
    func getTeamColor(callback: @escaping (Color) -> Void) {
        let teamKey = "Team/\(self.names.code.uppercased())"
        
        getCodeColor(teamKey: teamKey, callback: callback)
    }
}

extension Team {
    func getTeamColor(callback: @escaping (Color) -> Void) {
        let teamKey = "Team/\(self.code.uppercased())"
        
        getCodeColor(teamKey: teamKey, callback: callback)
    }
}
