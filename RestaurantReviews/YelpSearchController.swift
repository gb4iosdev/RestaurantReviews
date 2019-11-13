//
//  YelpSearchController.swift
//  RestaurantReviews
//
//  Created by Pasan Premaratne on 5/9/17.
//  Copyright © 2017 Treehouse. All rights reserved.
//

import UIKit
import MapKit

class YelpSearchController: UIViewController {
    
    // MARK: - Properties
    
    let searchController = UISearchController(searchResultsController: nil)
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    
    let dataSource = YelpSearchResultsDataSource()
    
    lazy var locationManager: LocationManager = {
        return LocationManager(locationsDelegate: self, permissionsDelegate: nil)
    }()
    
    lazy var client: YelpClient = {
        //let yelpAccount = YelpAccount.loadFromKeychain()
        //let oauthToken = yelpAccount!.accessToken
        //let apiKey = yelpAccount!.
        return YelpClient(apiKey: "Q2CsAjnT5d_K1hq5uwIhCuLag7LOo4PYshR1MBNbxt7HtLDun4-zSxEB-LZ3HwBLkfLpRJIR-JmvpMlECv2CC1MSCQOpNkUDy5RyNqAYqzcpAZZM6xw0F-5x40kcXHYx")  //Need to modify this to setup the Yelp Account, Use loadFromKeyChain etc.
    }()
    
    var coordinate: Coordinate? {
        didSet {
            if let coordinate = coordinate {
                showNearbyRestaurants(at: coordinate)
            }
        }
    }
    
    let queue = OperationQueue()
    
    
    var isAuthorized: Bool {
        let isAuthorizedWithYelp = YelpAPIClient.isAuthorized   //Was YelpAccount.isAuthorized!!!
        let isAuthorizedForLocation = LocationManager.isAuthorized
        return isAuthorizedWithYelp && isAuthorizedForLocation
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchBar()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isAuthorized {
            //  To bring up a list of nearby restaurants using User's current location, without the user having to search for anything
           locationManager.requestLocation()
        } else {
            checkPermissions()
        }
    }
    
    // MARK: - Table View
    func setupTableView() {
        self.tableView.dataSource = dataSource
        self.tableView.delegate = self
    }
    
    func showNearbyRestaurants(at coordinate: Coordinate) {
        client.search(withTerm: "", at: coordinate) {[weak self] result in
            switch result {
            case .success(let businesses):
                self?.dataSource.update(with: businesses)
                self?.tableView.reloadData()
                //self?.mapView.addAnnotations(businesses)
                let annotations: [MKPointAnnotation] = businesses.map { business in
                    let point = MKPointAnnotation()
                    point.coordinate = CLLocationCoordinate2D(latitude: business.location.latitude, longitude: business.location.longitude)
                    point.title = business.name
                    point.subtitle = business.subtitle
                    return point
                }
                self?.mapView.addAnnotations(annotations)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    
    // MARK: - Search
    
    func setupSearchBar() {
        self.navigationItem.titleView = searchController.searchBar
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
    }
    
    // MARK: - Permissions
    
    /// Checks (1) if the user is authenticated against the Yelp API and has an OAuth
    /// token and (2) if the user has authorized location access for whenInUse tracking.
    func checkPermissions() {
        let isAuthorizedWithYelp = YelpAPIClient.isAuthorized   //Was YelpAccount.isAuthorized!!!
        let isAuthorizedForLocation = LocationManager.isAuthorized
        
        let permissionsController = PermissionsController(isAuthorizedForLocation: isAuthorizedForLocation, isAuthorizedWithToken: isAuthorizedWithYelp)
        present(permissionsController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension YelpSearchController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let business = dataSource.object(at: indexPath)
        let detailsOperation = YelpBusinessDetailsOperation(business: business, client: self.client)
        let reviewsOperation = YelpBusinessReviewsOperation(business: business, client: self.client)
        
        reviewsOperation.addDependency(detailsOperation)    //So that the reviews operation executes only after the detailsOperation is complete
        
        reviewsOperation.completionBlock = {    //Performs segue after both operations have completed
            DispatchQueue.main.async {
                self.dataSource.update(business, at: indexPath)
                self.performSegue(withIdentifier: "showBusiness", sender: nil)
            }
        }
        
        queue.addOperation(detailsOperation)
        queue.addOperation(reviewsOperation)
    }
}

// MARK: - Search Results
extension YelpSearchController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchTerm = searchController.searchBar.text, let coordinate = coordinate else { return }
        
        if !searchTerm.isEmpty {
            client.search(withTerm: searchTerm, at: coordinate) {[weak self] result in
                switch result {
                case .success(let businesses):
                    self?.dataSource.update(with: businesses)
                    self?.tableView.reloadData()
                    
                    self?.mapView.removeAnnotations(self!.mapView.annotations)
                    //self?.mapView.addAnnotations(businesses)
                    let annotations: [MKPointAnnotation] = businesses.map { business in
                        let point = MKPointAnnotation()
                        point.coordinate = CLLocationCoordinate2D(latitude: business.location.latitude, longitude: business.location.longitude)
                        point.title = business.name
                        point.subtitle = business.subtitle
                        return point
                    }
                    self?.mapView.addAnnotations(annotations)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}

// MARK: - Navigation
extension YelpSearchController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBusiness" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let business = dataSource.object(at: indexPath)
                let detailController = segue.destination as! YelpBusinessDetailController
                detailController.business = business
                detailController.dataSource.updateData(business.reviews)
            }
        }
    }
}

// MARK: - Location Manager Delegate
extension YelpSearchController: LocationManagerDelegate {
    func obtainedCoordinates(_ coordinate: Coordinate) {
        self.coordinate = coordinate
        adjustMap(with: coordinate)
    }
    
    func failedWithError(_ error: LocationError) {
        print(error)
    }
}

// MARK: - MapKit
extension YelpSearchController {
    func adjustMap(with coordinate: Coordinate) {
        let coordinate2D = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let span = MKCoordinateRegionMakeWithDistance(coordinate2D, 2500, 2500).span
        let region = MKCoordinateRegion(center: coordinate2D, span: span)
        mapView.setRegion(region, animated: true)
    }
}


