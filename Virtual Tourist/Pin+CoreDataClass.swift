//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by mac on 1/24/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    convenience init(long: Float, lat: Float, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.long = long
            self.lat = lat
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
