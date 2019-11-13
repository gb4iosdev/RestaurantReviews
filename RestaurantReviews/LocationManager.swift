//
//  LocationManager.swift
//  RestaurantReviews
//
//  Created by Gavin Butler on 12-05-2019.
//  Copyright © 2019 Treehouse. All rights reserved.
//

import Foundation
import CoreLocation

extension Coordinate {
    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}

enum LocationError: Error {
    case unknownError
    case disallowedByUser
    case unableToFindLocation
}

protocol LocationPermissionsDelegate: class {
    func authorizationSucceeded()
    func authorizationFailedWithStatus(_ status: CLAuthorizationStatus)
}

protocol LocationManagerDelegate: class {
    func obtainedCoordinates(_ coordinate: Coordinate)
    func failedWithError(_ error: LocationError)
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    weak var permissionsDelegate: LocationPermissionsDelegate?
    weak var locationsDelegate: LocationManagerDelegate?
    
    init(locationsDelegate: LocationManagerDelegate?, permissionsDelegate: LocationPermissionsDelegate?) {
        self.permissionsDelegate = permissionsDelegate
        self.locationsDelegate = locationsDelegate
        super.init()
        manager.delegate = self
    }
    
    static var isAuthorized: Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse: return true
        default: return false
        }
    }
    
    func requestLocationAuthorization() throws {
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        print("Auth status is: \(authorizationStatus.rawValue)")
        
        if authorizationStatus == .restricted || authorizationStatus == .denied {
            throw LocationError.disallowedByUser
        } else if authorizationStatus == .notDetermined {
            print("just about to call reqWhenInUseAuth")
            manager.requestWhenInUseAuthorization()
            print("straight after reqWhenInUseAuth call and status is: \(CLLocationManager.authorizationStatus().rawValue)")
        } /*else if authorizationStatus == .authorizedWhenInUse {     //Can be maintained in the simulator from previous sessions...
            permissionsDelegate?.authorizationSucceeded()
        }*/ else {
            print("Returning without doing anything")
            return
        }
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Got into locationManager callback and status is: \(CLLocationManager.authorizationStatus().rawValue)")
        if status == .authorizedWhenInUse {
            permissionsDelegate?.authorizationSucceeded()
        } else if status == .restricted || status == .denied {
            permissionsDelegate?.authorizationFailedWithStatus(status)
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let error = error as? CLError else {
            locationsDelegate?.failedWithError(.unknownError)
            return
        }
        
        switch error.code {
        case .locationUnknown, .network: locationsDelegate?.failedWithError(.unableToFindLocation)
        case .denied: locationsDelegate?.failedWithError(.disallowedByUser)
        default: return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationsDelegate?.failedWithError(.unableToFindLocation)
            return
        }
        
        let coordinate = Coordinate(location: location)
        
        locationsDelegate?.obtainedCoordinates(coordinate)
        
    }
}
