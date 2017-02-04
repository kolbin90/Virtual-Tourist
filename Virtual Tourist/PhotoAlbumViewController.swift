//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by mac on 2/4/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate {
    
    // MARK: - Variables
    var pin: MKAnnotation?
    
    
    
    
    
    // MARK: - Oulets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: - MapView Delegate
    
    // MARK: - Lifecycle 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showAnnotations([pin!], animated: true)

    }
    
    // MARK: - CollectionView delegate
    
    // MARK: - Assist functions
    
    
    
    
    // MARK:- Actions
    
    @IBAction func editButton(_ sender: Any) {
    }
    
}
