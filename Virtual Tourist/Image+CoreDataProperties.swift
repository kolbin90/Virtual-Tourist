//
//  Image+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by mac on 1/24/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import Foundation
import CoreData


extension Image {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image");
    }
    @NSManaged public var imageURL: String
    @NSManaged public var imageData: Data?
    @NSManaged public var toPin: Pin?
}
