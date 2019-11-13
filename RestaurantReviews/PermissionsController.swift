//
//  PermissionsController.swift
//  RestaurantReviews
//
//  Created by Pasan Premaratne on 5/9/17.
//  Copyright © 2017 Treehouse. All rights reserved.
//

import UIKit
import OAuth2   //The framework that provides the OAuth functionality.  Inserted into the project using Carthage.  Simply create the OAuth2ClientCredentials object with a dictionary of settings, then call the 'authorize' method.
import CoreLocation

class PermissionsController: UIViewController, LocationPermissionsDelegate {
    
    //  See also Github OAuth2 Technical Documentation:
    
    let oauth = OAuth2ClientCredentials(settings: [
        "client_id": "oaQ6XuRwXIyXZ6za8vz09g",
        "client_secret": "Q2CsAjnT5d_K1hq5uwIhCuLag7LOo4PYshR1MBNbxt7HtLDun4-zSxEB-LZ3HwBLkfLpRJIR-JmvpMlECv2CC1MSCQOpNkUDy5RyNqAYqzcpAZZM6xw0F-5x40kcXHYx",
        "authorize_uri": "https://github.com/login/oauth/authorize",
        "token_uri": "https://github.com/login/oauth/access_token",   // code grant only
        "redirect_uris": ["myapp://oauth/callback"],   // register your own "myapp" scheme in Info.plist
        "scope": "user repo:status",
        "secret_in_body": true,    // Github needs this
        "keychain": false,
        ])
    
    lazy var locationManager: LocationManager = {
        return LocationManager(locationsDelegate: nil, permissionsDelegate: self)
    }()
    
    /*
     From Someone else on Treehouse:
    let apiToken = "veryLongSecretAPIToken"
    let bearerString = "Bearer \(apiToken)"
    
    let endpointURL = URL(string: "https://api.yelp.com/v3/businesses/someBusiness")!
    let yelpRequest = URLRequest(url: endpointURL)
    yelpRequest.addValue(bearerString, forHTTPHeaderField: "Authorization")*/
    
/*From Passan:
 let apiKey = "your_api_key"
 var url = URL(string: "https://api.yelp.com/v3/businesses/search?term=delis&latitude=37.786882&longitude=-122.399972")!
 var request = URLRequest(url: url)
 request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
 */
    
    var isAuthorizedForLocation: Bool
    var isAuthenticatedWithToken: Bool
    
    lazy var locationPermissionButton:  UIButton = {
        let title = self.isAuthorizedForLocation ? "Location Permissions Granted" : "Request Location Permissions"
        let button = UIButton(type: .system)
        let controlState = self.isAuthorizedForLocation ? UIControlState.disabled : UIControlState.normal
        button.isEnabled = !self.isAuthorizedForLocation
        button.setTitle(title, for: controlState)
        button.addTarget(self, action: #selector(PermissionsController.requestLocationPermissions), for: .touchUpInside)
        
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 62/255.0, green: 71/255.0, blue: 79/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 178/255.0, green: 187/255.0, blue: 185/255.0, alpha: 1.0), for: .disabled)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        
        return button
    }()
    
    lazy var oauthTokenButton:  UIButton = {
        let title = self.isAuthenticatedWithToken ? "OAuth Token Granted" : "Request OAuth Token"
        let button = UIButton(type: .system)
        let controlState = self.isAuthenticatedWithToken ? UIControlState.disabled : UIControlState.normal
        button.isEnabled = !self.isAuthenticatedWithToken
        button.setTitle(title, for: controlState)
        button.addTarget(self, action: #selector(PermissionsController.requestOAuthToken), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 62/255.0, green: 71/255.0, blue: 79/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 178/255.0, green: 187/255.0, blue: 185/255.0, alpha: 1.0), for: .disabled)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        
        return button
    }()
    
    lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Dismiss", for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(PermissionsController.dismissPermissions), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder not implemented")
    }
    
    init(isAuthorizedForLocation locationAuthorization: Bool, isAuthorizedWithToken tokenAuthorization: Bool) {
        self.isAuthorizedForLocation = locationAuthorization
        self.isAuthenticatedWithToken = tokenAuthorization
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 95/255.0, green: 207/255.0, blue: 128/255.0, alpha: 1.0)
    }
    

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let stackView = UIStackView(arrangedSubviews: [locationPermissionButton, oauthTokenButton])
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 16.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        view.addSubview(dismissButton)
        
        NSLayoutConstraint.activate([
            locationPermissionButton.heightAnchor.constraint(equalToConstant: 64.0),
            locationPermissionButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            locationPermissionButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            oauthTokenButton.heightAnchor.constraint(equalToConstant: 64.0),
            oauthTokenButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            oauthTokenButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32.0),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32.0),
            dismissButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
    }
    
    func requestLocationPermissions() {
        do {
            try locationManager.requestLocationAuthorization()
        } catch LocationError.disallowedByUser {
            //  Show an alert to users
            launchAlert()
        } catch let error {
            print("Location Authorization Error: \(error.localizedDescription)")
        }
        
    }
    
    func requestOAuthToken() {
        //Authorize method has a completion handler that returns the token information if successful, or error if not
        oauth.authorize { authParams, error in
            if let params = authParams {
                guard let token = params["access_token"] as? String, let expiration = params["expires_in"] as? TimeInterval else { return }
                //Going to now safe the token information to disk - see YelpAccount.swift
                let account = YelpAccount(accessToken: token, expiration: expiration, grantDate: Date())
                
                do {
                    try? account.save()
                    self.oauthTokenButton.setTitle("OAuth Token Granted", for: .disabled)
                    self.oauthTokenButton.isEnabled = true
                }
                
            } else {
                print("Authorization was cancelled or went wrong: \(error!)")
            }
        }
    }
    
    func dismissPermissions() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK:  Location Permissions Delegate
    func authorizationSucceeded() {
        print("Got into authorizationSucceeded method")
        locationPermissionButton.setTitle("Location Permissions Granted", for: .disabled)
        locationPermissionButton.isEnabled = false
    }
    
    func authorizationFailedWithStatus (_ status: CLAuthorizationStatus) {
        launchAlert()
        //UIApplication.shared.open(URL(string:"App-Prefs:root=LOCATION_SERVICES")!, options: [:], completionHandler: nil)
    }
    
    func launchAlert() {
        let alertController = UIAlertController (title: "Location Permissions have been denied by user", message: "Go to Settings?", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

}
