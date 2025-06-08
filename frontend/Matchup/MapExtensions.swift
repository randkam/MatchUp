import SwiftUI
import MapKit

// Extension to convert MKCoordinateRegion to MapCameraPosition for iOS 17+ Map API
extension MKCoordinateRegion {
    func toMapCameraPosition() -> MapCameraPosition {
        return .region(self)
    }
}

// Note: IdentifiableCoordinate is already defined in Models.swift
