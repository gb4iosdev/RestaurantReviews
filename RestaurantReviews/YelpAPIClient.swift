//
//  YelpAPIClient.swift
//  RestaurantReviews
//
//  Created by Gavin Butler on 20-05-2019.
//  Copyright © 2019 Treehouse. All rights reserved.
//

import Foundation
import Locksmith

class YelpAPIClient {
    var clientID: String {
        return "oaQ6XuRwXIyXZ6za8vz09g"
        // ideally fetched from keychain or somewhere secure
    }
    var apiKey: String {
        // ideally fetched from keychain or somewhere secure
        return "Q2CsAjnT5d_K1hq5uwIhCuLag7LOo4PYshR1MBNbxt7HtLDun4-zSxEB-LZ3HwBLkfLpRJIR-JmvpMlECv2CC1MSCQOpNkUDy5RyNqAYqzcpAZZM6xw0F-5x40kcXHYx"
    }
    
    static var clientIDFromKeyChain: String?
    static var apiKeyFromKeyChain: String?
    
    static let service = "Yelp"
    
    let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func searchBusinesses() {
        let endpoint = Yelp.business(id: "abcdefg")
        // Inside the client, when we retrieve the request object from the endpoint, we're
        // passing in the apiKey
        let request = endpoint.request(withApiKey: apiKey)
        
        // Do the usual stuff!
    }
}

extension YelpAPIClient {
    
    static var isAuthorized: Bool {     //Not a good name.  Should be canRetrieveCredentials
        return true
        /*Passan's code:
         if let _ = loadFromKeychain() {
         return true
         } else {
         return false
         }*/
    }
    
    struct Keys {
        static let clientID = "clientID"
        static let apiKey = "apiKey"
    }
    
    func save() throws {
        try Locksmith.saveData(data: [Keys.clientID: clientID, Keys.apiKey: apiKey], forUserAccount: YelpAccount.service)
    }
    
    static func loadFromKeychain() -> Bool {
        guard let dictionary = Locksmith.loadDataForUserAccount(userAccount: YelpAccount.service), let clientIDFromKeyChain = dictionary[Keys.clientID] as? String, let apiKeyFromKeyChain = dictionary[Keys.apiKey] as? String else {return false}
        
        self.clientIDFromKeyChain = clientIDFromKeyChain
        self.apiKeyFromKeyChain = apiKeyFromKeyChain
        
        return true
    }
}

