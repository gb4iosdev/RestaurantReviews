//
//  Result.swift
//  RestaurantReviews
//
//  Created by Gavin Butler on 20-05-2019.
//  Copyright © 2019 Treehouse. All rights reserved.
//

import Foundation

enum Result<T, U> where U: Error {
    case success(T)
    case failure(U)
}
