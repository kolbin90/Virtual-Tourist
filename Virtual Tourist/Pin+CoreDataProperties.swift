//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by mac on 1/24/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin");
    }

    @NSManaged public var long: Float
    @NSManaged public var lat: Float
    @NSManaged public var toImage: NSSet?

}

// MARK: Generated accessors for toImage
extension Pin {

    @objc(addToImageObject:)
    @NSManaged public func addToToImage(_ value: Image)

    @objc(removeToImageObject:)
    @NSManaged public func removeFromToImage(_ value: Image)

    @objc(addToImage:)
    @NSManaged public func addToToImage(_ values: NSSet)

    @objc(removeToImage:)
    @NSManaged public func removeFromToImage(_ values: NSSet)

}
