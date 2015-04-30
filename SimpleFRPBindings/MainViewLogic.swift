//
//  ViewOptions.swift
//  FRPBindingExample
//
//  Created by developer on 4/7/15.
//  Copyright (c) 2015 letvargo. All rights reserved.
//

import SimpleSwiftFRP

final class MainViewLogic {
    
    // A single-case enum that represents a knock on the door.
    enum Knock { case Knock }
    
    // An unowned reference to the view controller
    private unowned var controller: MainViewController
    
    // Declare and initialice the Sources. Note that there is one
    // Source for each control that will be sending a value.
    let srcKnock                    = Source<Knock>()
    let srcLightSwitch              = Source<Int>()
    let srcAtHome                   = Source<Int>()
    
    // Declare and initialize the Streams
    private let sKnockToShow        = Stream<Bool>()
    private let sLightToHide        = Stream<Bool>()
    private let sAtHomeToHide       = Stream<Bool>()
    
    // Declare and initialize the Cells
    private let cAtHome             = Cell(initialValue: true)
    private let cLightsOn           = Cell(initialValue: false)
    private let cShouldShowMessage  = Cell(initialValue: false)
    private let cMessage            = Cell(initialValue: "")
    
    // Declare and initialize the Outlets
    private let oEnableLights       = Outlet<Bool>()
    private let oSetMessage         = Outlet<String>()
    
    // The init method
    init(controller: MainViewController) {
        self.controller = controller
        wire()
    }
    
    // The wire() method connects all of the Sources, Streams, Cells, and Outlets together.
    // It is called by the view controller in its awakeFromNib() method, after
    // all possible nibs have been initialized. The wire() method contains all of the
    // logic for the view controller. It is totally referentially transparent and causes
    // no side effects other than those specifically called by the two Outlets.
    
    private func wire() {
        
        // Lift srcLightSwitch into a Cell, transforming the Int value
        // of the button state into a Bool value
        
        srcLightSwitch
            --^ (cLightsOn, buttonStateToBool)
        
        // Lift srcAtHome into a Cell, transforming the Int value of
        // the button state into a Bool and then attach an Outlet that
        // will disable the light switch when no one is home.
        
        srcAtHome
            --^ (cAtHome, buttonStateToBool)
                --< (oEnableLights, controller.setLightsEnabled)
        
        // Merge the three sources into a single Cell after mapping them
        // all to Stream<Bool>. The Cell will store the most recent Bool
        // value that will define whether the message should be shown or not.
        
        [
            srcKnock
                >-- (sKnockToShow, returnShow),
            srcLightSwitch
                >-- (sLightToHide, returnHide),
            srcAtHome
                >-- (sAtHomeToHide, returnHide)
        ]
                    --& cShouldShowMessage
        
        // Compute the String value of the message based on the values
        // stored in the three cells, and then attach an Outlet to
        // actually show the correct message on the label.
        
        (
            cShouldShowMessage,
            cAtHome,
            cLightsOn
        )
                --^ (cMessage, messageToShow)
                    --< (oSetMessage, controller.setMessage)
    }
}

// The closures and functions defined below are used inside the wire() method.
// By declaring them outside of the class and marking them private we are
// guaranteed that there will be no reference to any local state -
// they operate on nothing other than the arguments passed to them.

private let returnShow: MainViewLogic.Knock -> Bool = { _ in true }
private let returnHide: Int -> Bool                 = { _ in false }

private func buttonStateToBool(state: Int) -> Bool {
    return state == NSOnState
        ? true
        : false
}

private func messageToShow(shouldShow: Bool, atHome: Bool, lightsOn: Bool) -> String {
    if !shouldShow || !atHome {
        return ""
    } else {
        return lightsOn
            ? "Welcome!"
            : "Go Away!"
    }
}