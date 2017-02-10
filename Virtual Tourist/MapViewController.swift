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
    var pandasForDelition = [PinAndAnnotation]() // panda = PinANDAnnotation
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.removeAnnotations(mapView.annotations)
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
        
        /*
        do{
         try stack.dropAllData()
         mapView.removeAnnotations(mapView.annotations)
         } catch {
         print("Error droping all objects in DB")
         } */
    }
    
    
    
    // MARK: - MKMapViewDelegate
    // Here we create a view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "purpleDropPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .purple
        }
        else {
            pinView!.annotation = annotation
            pinView!.pinTintColor = .purple
            
        }
        return pinView
    }
    
    // Check if region've been changed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    // Check of pin was selected
    func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView) {
        if editingMode {
            guard let pin = didSelect as? MKPinAnnotationView else {
                return
            }
            if pin.pinTintColor == UIColor.red {
                pin.pinTintColor = .purple
                for (index,pandaForDelition) in pandasForDelition.enumerated() {
                    let annotation = pandaForDelition.annotation
                    if (annotation.coordinate.latitude == pin.annotation!.coordinate.latitude) && (annotation.coordinate.longitude == pin.annotation!.coordinate.longitude) {
                        pandasForDelition.remove(at: index)
                    }
                }
            } else {
                let onePanda:PinAndAnnotation = PinAndAnnotation(pinAnnotationView: pin)
                pandasForDelition.append(onePanda)
                pin.pinTintColor = .red
            }
            setTitleForDelete(done: false)
            mapView.deselectAnnotation(didSelect.annotation, animated: true)
        } else {
         let controller = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
         
         // deselect the pin so we can comeback and select it again
            mapView.deselectAnnotation(didSelect.annotation, animated: true)
         
         controller.pin = didSelect.annotation
         navigationController?.pushViewController(controller, animated: true)
            
        }
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
 
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        guard editingMode == false else {
            return
        }
        
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let newCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let lat = Float(newCoordinates.latitude)
            let long = Float(newCoordinates.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            self.mapView.addAnnotation(annotation)
            let newPin = Pin(long: long, lat: lat, context: stack.context)
            stack.save()
            FlickrClient.sharedInstance().getImagesFromFlickr(pin: newPin) { (result, error) in
                print("Vodnikov LLIac \(result?.count)")
                DispatchQueue.main.async {
                    if let result = result {
                        print("oi oi oi OLLIu6ka")
                        FlickrClient.sharedInstance().getImagesDataFor(pin: newPin)
                        self.stack.save()

                    }
                }
            }
        }
        if gestureRecognizer.state == UIGestureRecognizerState.ended {

        }
    }
    
    func getAnnotationsFromCore() {
        do {
            let pins = try stack.context.fetch(Pin.fetchRequest()) as [Pin]
            var annotations = [MKPointAnnotation]()
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
        let annotationsForDeletion = pandaToAnnotation(pandas: pandasForDelition)
        for annotation in annotationsForDeletion {
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            let coordinates = [Float(annotation.coordinate.latitude),Float(annotation.coordinate.longitude)]
            let predicate = NSPredicate.init(format: "(lat == %@) AND (long == %@)", argumentArray: coordinates)
            fr.predicate = predicate
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
        mapView.removeAnnotations(pandaToAnnotation(pandas: pandasForDelition))
        deleteAnnotationsFromCore()
        pandasForDelition = []
        setTitleForDelete(done: false)
    }
    
    
    @IBAction func editButton(_ sender: Any) {
        if editingMode == false {
            editingMode = true
            setTitleForDelete(done: false)
            editButton.title = "Done"
            
        } else {
            let deleteArray = pandaToPin(pandas: pandasForDelition)
            for pin in deleteArray {
                pin.pinTintColor = .purple
            }
            pandasForDelition = []
            editButton.title = "Edit"
            setTitleForDelete(done:true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.editingMode = false
            }
            
        }
    }
    
    
    func pandaToAnnotation(pandas: [PinAndAnnotation]) -> [MKAnnotation] {
        var annotations = [MKAnnotation]()
        for panda in pandas {
            let annotation = panda.annotation
            annotations.append(annotation)
        }
        return annotations
    }
    
    func pandaToPin(pandas: [PinAndAnnotation]) -> [MKPinAnnotationView] {
        var pins = [MKPinAnnotationView]()
        for panda in pandas {
            let pin = panda.pin
            pins.append(pin)
        }
        return pins
    }
    

    
    func setTitleForDelete(done:Bool) {
        if done {
            deleteButton.title! = "Delete"
            deleteButton.isEnabled = false
        } else {
            if editingMode {
                deleteButton.isEnabled = true
                deleteButton.title! = "Delete(\(pandasForDelition.count))"
            } else {
                deleteButton.title! = "Delete"
                deleteButton.isEnabled = false
            }
        }
    }
}
