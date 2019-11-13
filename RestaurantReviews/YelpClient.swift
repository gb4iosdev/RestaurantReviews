//
//  YelpClient.swift
//  RestaurantReviews
//
//  Created by Gavin Butler on 21-05-2019.
//  Copyright © 2019 Treehouse. All rights reserved.
//

import Foundation

class YelpClient: APIClient {
    let session: URLSession
    //private let token: String   //  GB:  Won't need this
    private let apiKey: String
    
    init(configuration: URLSessionConfiguration, apiKey: String) {
        self.session = URLSession(configuration: configuration)
        self.apiKey = apiKey
    }
    
    convenience init(apiKey: String) {  //  GB:  Won't need this
        self.init(configuration: .default, apiKey: apiKey)
    }
    
    func search (withTerm term: String, at coordinate: Coordinate, categories: [YelpCategory] = [], radius: Int? = nil, limit: Int = 50, sortBy sortType: Yelp.YelpSortType = .rating, completion: @escaping (Result<[YelpBusiness], APIError>) -> Void) {
        
        let endpoint = Yelp.search(term: term, coordinate: coordinate, radius: radius, categories: categories, limit: limit, sortBy: sortType)
        
        //let request = endpoint.requestWithAuthorizationHeader(oauthToken: token)    //GB:  This needs to change
        let request = endpoint.request(withApiKey: apiKey)
        
        fetch(with: request, parse: { json -> [YelpBusiness] in
            guard let businesses = json["businesses"] as? [[String: Any]] else { return [] }
            
            return businesses.flatMap {YelpBusiness(json: $0)}
        
        }, completion: completion)
    }
    
    func businessWithId(_ id: String, completion: @escaping (Result<YelpBusiness, APIError>) -> Void) {
        let endPoint = Yelp.business(id: id)
        let request = endPoint.request(withApiKey: self.apiKey)
        
        fetch(with: request, parse: { json -> YelpBusiness? in
            return YelpBusiness(json: json)
        }, completion: completion)
    }
    
    func updateWithHoursAndPhotos(_ business: YelpBusiness, completion: @escaping (Result<YelpBusiness, APIError>) -> Void) {
        let endPoint = Yelp.business(id: business.id)
        let request = endPoint.request(withApiKey: self.apiKey)
        
        fetch(with: request, parse: { json -> YelpBusiness? in
            business.updateWithHoursAndPhotos(json: json)
            return business
        }, completion: completion)
    }
    
    func reviews(for business: YelpBusiness, completion: @escaping (Result<[YelpReview], APIError>) -> Void) {
        let endpoint = Yelp.reviews(businessId: business.id)
        let request = endpoint.request(withApiKey: self.apiKey)
        
        fetch(with: request, parse: { json -> [YelpReview] in
            guard let reviews = json["reviews"] as? [[String: Any]] else { return [] }
            return reviews.flatMap { YelpReview(json: $0) }
        }, completion: completion)
    }
}
