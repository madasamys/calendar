//
//  ViewController.swift
//  calendar
//
//  Created by Madasamy Sankarapandian on 01/12/2016.
//  Copyright © 2016 mCruncher. All rights reserved.
//

import UIKit
import EventKit
import EventKitUI

class ViewController: UIViewController {
    
    let eventStore = EKEventStore()
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAccessToCalendar()
        loadEvents()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.storeChanged(_:)), name: NSNotification.Name.EKEventStoreChanged, object: eventStore)
    }
    
    func storeChanged(_ nsNotification: NSNotification) {
        print("Method invoked")
        print("Event name \(nsNotification)")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func  saveCalendar() {
        let calender = EKCalendar(for: .event, eventStore: eventStore)
        calender.title = "Furiend"
        // calender.allowedEntityTypes
        // let sourcesInEventStore = eventStore.sources
        //        calender.source = sourcesInEventStore.filter { (source: EKSource) -> Bool in
        //            source.sourceType.rawValue == EKSourceType.local.rawValue
        //            }.first!
        calender.source = eventStore.defaultCalendarForNewEvents.source
        do {
            let calendarIdentifier = userDefaults.string(forKey: "EventTrackerPrimaryCalendar")
            if calendarIdentifier == nil  {
                try eventStore.saveCalendar(calender, commit: true)
                userDefaults.set(calender.calendarIdentifier, forKey: "EventTrackerPrimaryCalendar")
                userDefaults.synchronize()
            }
        } catch  {
            print("Error occurred while creating calendar ")
        }
    }
    
    @IBAction func addNewEvent(_ sender: Any) {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            if accessGranted == true {
                let eventController = EKEventEditViewController()
                let calenderIdentifier = self.userDefaults.string(forKey: "EventTrackerPrimaryCalendar")
                let calendar = self.eventStore.calendar(withIdentifier: calenderIdentifier!)
                eventController.eventStore = self.eventStore
                eventController.editViewDelegate = self
                let event = EKEvent(eventStore: self.eventStore)
                event.title = "Foo"
                event.calendar = calendar!
                eventController.event = event
                self.present(eventController, animated: true, completion: nil)
            } else {
            }
        })
    }
    
    func requestAccessToCalendar() {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    // self.loadCalendars()
                    // self.refreshTableView()
                    self.saveCalendar()
                })
            } else {
                DispatchQueue.main.async(execute: {
                    // self.needPermissionView.fadeIn()
                })
            }
        })
    }
    
    func loadEvents() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Create start and end date NSDate instances to build a predicate for which events to select
        let startDate = dateFormatter.date(from: "2016-01-01")
        let endDate = dateFormatter.date(from: "2016-12-31")
        let calenderIdentifier = self.userDefaults.string(forKey: "EventTrackerPrimaryCalendar")
        let calendar = self.eventStore.calendar(withIdentifier: calenderIdentifier!)
        let eventPredicate = eventStore.predicateForEvents(withStart: startDate!, end: endDate!, calendars: [calendar!])
        let events = eventStore.events(matching: eventPredicate).sorted(){
            (e1: EKEvent, e2: EKEvent) -> Bool in
            return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
        }
        for event in events {
            print(event.title)
            print(event.calendar.title)
            print(event.notes ?? "")
            print(event.startDate)
        }
    }
    
}

extension ViewController: EKEventEditViewDelegate {
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.dismiss(animated: true, completion: nil)
    }
}

