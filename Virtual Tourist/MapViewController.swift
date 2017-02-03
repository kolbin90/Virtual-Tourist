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
    var dropingPin = true
    var unselected = true
    var pinsForDeletion = [MKAnnotation]()
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self // MKMapViewDelegate
        setTitleForDelete(done: false)
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            loadMapRegion()
        } else {
            saveMapRegion()
        }
        
        // Set touch recognizer
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(addAnnotation(gestureRecognizer:)))
        mapView.addGestureRecognizer(gestureRecognizer)
        getAnnotationsFromCore()
        
        
        /* do{
         try stack.dropAllData()
         mapView.removeAnnotations(mapView.annotations)
         } catch {
         print("Error droping all objects in DB")
         }*/
    }
    
    
    
    
    
    
    
    // MARK: - MKMapViewDelegate
    
    // Here we create a view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if editingMode {
            if unselected {
                let reuseId = "redPin"
                var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
                if pinView == nil {
                    pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                    pinView!.animatesDrop = false
                    pinView?.pinTintColor = .red
                }
                else {
                    pinView!.annotation = annotation
                }
                return pinView
                
            } else {
                let reuseId = "purplePin"
                var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
                if pinView == nil {
                    pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                    pinView!.animatesDrop = false
                    pinView?.pinTintColor = .purple
                }
                else {
                    pinView!.annotation = annotation
                }
                unselected = true
                return pinView
            }
        } else {
            let reuseId = "purpleDropPin"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.animatesDrop = true
                pinView?.pinTintColor = .purple
            }
            else {
                pinView!.annotation = annotation
            }
            return pinView
        }
    }
    
    
    // Check if region've been changed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    // Check of pin was selected
    func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView) {
        if editingMode {
            let newAnnotation = didSelect.annotation!
            let oldAnnotationView = didSelect as? MKPinAnnotationView
            if oldAnnotationView?.pinTintColor == UIColor.red {
                unSelectPin(annotation: newAnnotation)
            } else {
                mapView.removeAnnotation(didSelect.annotation!)
                mapView.addAnnotation(newAnnotation)
                pinsForDeletion.append(newAnnotation)
            }
            setTitleForDelete(done: false)
            mapView.deselectAnnotation(didSelect.annotation, animated: true)
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
        if let coordinatesArray = UserDefaults.standard.object(forKey: "Region") as? [Double] {
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
        let coordinatesArray = [mapView.region.center.latitude, mapView.region.center.longitude, mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta]
        UserDefaults.standard.set(coordinatesArray, forKey: "Region")
    }
    
    // MARK: - Annotations
    
    
    func unSelectPin(annotation:MKAnnotation) {
        
        var newAnnotation = annotation
        
        mapView.removeAnnotation(annotation)
        unselected = false
        mapView.addAnnotation(newAnnotation)
        for (index,pin) in pinsForDeletion.enumerated() {
            if (pin.coordinate.latitude == newAnnotation.coordinate.latitude) && (pin.coordinate.longitude == newAnnotation.coordinate.longitude) {
                pinsForDeletion.remove(at: index)
            }
        }
        
        
        setTitleForDelete(done: false)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        guard editingMode == false else {
            return
        }
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let newCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let lat = Float(newCoordinates.latitude)
            let long = Float(newCoordinates.longitude)
            Pin(long: long, lat: lat, context: stack.context)
            stack.save()
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = newCoordinates
            self.mapView.addAnnotation(annotation)
            
        }
        if gestureRecognizer.state == UIGestureRecognizerState.ended {
            // drag = false
        }
        
    }
    
    func getAnnotationsFromCore() {
        do {
            let pins = try stack.context.fetch(Pin.fetchRequest()) as [Pin]
            var annotations = [MKPointAnnotation()]
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = Double(pin.lat)
                annotation.coordinate.longitude = Double(pin.long)
                annotations.append(annotation)
            }
            self.mapView.addAnnotations(annotations)
        }  catch {
            print("ebat oshibka")
        }
    }
    
    func deleteAnnotationsFromCore() {
        for annotation in pinsForDeletion {
            //let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Pin.fetchRequest()
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            let coordinates = [Float(annotation.coordinate.latitude),Float(annotation.coordinate.longitude)]
            let predicate = NSPredicate.init(format: "(lat == %@) AND (long == %@)", argumentArray: coordinates)
            fr.predicate = predicate
            //NSPredicate(format: "notebook = %@", argumentArray: [notebook!])
            if let result = try? stack.context.fetch(fr) {
                print("try? stack.context.f")
                for object in result {
                    print("for object in result")
                    print(object)
                    stack.context.delete(object as! NSManagedObject)
                }
            } else {
                print("error with fetching")
            }
        }
        stack.save()
    }
    
    
    // MARK: - Actions
    
    @IBAction func deleteButton(_ sender: Any) {
        mapView.removeAnnotations(pinsForDeletion)
        deleteAnnotationsFromCore()
        pinsForDeletion = []
        setTitleForDelete(done: false)
    }
    
    
    @IBAction func editButton(_ sender: Any) {
        if editingMode == false {
            
            editingMode = true
            setTitleForDelete(done: false)
            editButton.title = "Done"
            
        } else {
            let deleteArray = pinsForDeletion
            for pin in deleteArray {
                unSelectPin(annotation: pin)
            }
            editButton.title = "Edit"
            setTitleForDelete(done:true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.editingMode = false
            }
            
        }
    }
    
    
    func setTitleForDelete(done:Bool) {
        if done {
            deleteButton.title! = "Delete"
            deleteButton.isEnabled = false
        } else {
            if editingMode {
                deleteButton.isEnabled = true
                deleteButton.title! = "Delete(\(pinsForDeletion.count))"
            } else {
                deleteButton.title! = "Delete"
                deleteButton.isEnabled = false
            }
        }
        
    }
    
    
}
