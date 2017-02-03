//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by mac on 1/24/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    //MARK: - Variables
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var editingMode = false
    var selectedPinsNum = 0
    var pinsForDeletion = [MKAnnotation]()
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self // MKMapViewDelegate
       // let context = stack.context
        
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            loadMapRegion()
        } else {
            saveMapRegion()
        }
        
        
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(addAnnotation(gestureRecognizer:)))
        mapView.addGestureRecognizer(gestureRecognizer)
        loadPins()

    }
    
    
    
    
    
    
    
    
    
    
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            var touchPoint = gestureRecognizer.location(in: self.mapView)
            var newCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let lat = Float(newCoordinates.latitude)
            let long = Float(newCoordinates.longitude)
            Pin(long: long, lat: lat, context: stack.context)
            stack.save()
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
          //  annotation.title = "hello"
            self.mapView.addAnnotation(annotation)
            
        }
        if gestureRecognizer.state == UIGestureRecognizerState.ended {
            // drag = false
        }
        
    }
    
    func loadPins() {
        print("1")
        do {
            let pins = try stack.context.fetch(Pin.fetchRequest()) as [Pin]
            print("2")
            var annotations = [MKPointAnnotation()]

            for pin in pins {
                print("3")

                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = Double(pin.lat)
                annotation.coordinate.longitude = Double(pin.long)
              //  annotation.title = "hello"
                annotations.append(annotation)
            }
            self.mapView.addAnnotations(annotations)

        }  catch {
            print("ebat oshibka")
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    // Here we create a view with a "right callout accessory view".
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
         //   pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        print("Vodnikov bylo: \(mapView.selectedAnnotations.count)")
        return pinView
    }
    

    

    
    // Check if region've been changed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
        
        func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView) {
            print("didSelectAnnotationView")
            if editingMode {
                didSelect.tintColor = UIColor.purple
                pinsForDeletion.append(didSelect.annotation!)
                selectedPinsNum += 1
                print(selectedPinsNum)
        }
        /*
        let controller = storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        
        // signal to cancel download in case there is a download in progress in background thread
        cancelDownload = true
        
        // deselect the pin so we can comeback and select it again
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        controller.pin = (view.annotation as! PinAnnotation).pin
        navigationController?.pushViewController(controller, animated: true) */
    }
    
    
    
    
    
    
    
    
    // MARK: - Persist region
    
    func loadMapRegion() {
        let coordinatesArray = UserDefaults.standard.object(forKey: "Region") as! [Double]
        if coordinatesArray != nil {
            let center = CLLocationCoordinate2DMake(
                coordinatesArray[0],
                coordinatesArray[1])
            let span = MKCoordinateSpan(
                latitudeDelta: coordinatesArray[2],
                longitudeDelta: coordinatesArray[3])
            let region = MKCoordinateRegionMake(center, span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func saveMapRegion() {
        
        let defaults = UserDefaults.standard
        let coordinatesArray = [mapView.region.center.latitude, mapView.region.center.longitude, mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta]
        defaults.set(coordinatesArray, forKey: "Region")    }
    
    
    
    
    @IBAction func deleteButton(_ sender: Any) {
        print("mapView.selectedAnnotations = \(mapView.selectedAnnotations.count)")
        mapView.removeAnnotations(pinsForDeletion)
    }
    
    
    @IBAction func editButton(_ sender: Any) {
        if editingMode == false {
            editingMode = true
            editButton.title = "Cancel"
        } else {
            editingMode = false
            editButton.title = "Edit"
        }
        
        
        
      /*  do {
            try stack.dropAllData()
            mapView.removeAnnotations(mapView.annotations)
        } catch {
            print("Error droping all objects in DB")
        } */
    }
    
    
    
    
}
