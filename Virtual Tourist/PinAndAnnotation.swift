//
//  PinAndAnnotation.swift
//  Virtual Tourist
//
//  Created by mac on 2/3/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import Foundation
import MapKit

class PinAndAnnotation {
    var pin:MKPinAnnotationView
    var annotation: MKAnnotation
    init(pinAnnotationView: MKPinAnnotationView) {
        pin = pinAnnotationView
        annotation = pinAnnotationView.annotation!
    }
}
