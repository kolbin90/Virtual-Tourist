//
//  Image+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by mac on 1/24/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import Foundation
import CoreData

@objc(Image)
public class Image: NSManagedObject {
    convenience init(imageURL:String,imageData: Data?, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Image", in: context) {
            self.init(entity: ent, insertInto: context)
            if let imageData = imageData {
                self.imageData = imageData
            }
            self.imageURL = imageURL
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
}
