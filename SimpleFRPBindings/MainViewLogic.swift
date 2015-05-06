//
//  MainViewController.swift
//  SimpleFRPBindings
//
//  Created by developer on 4/7/15.
//  Copyright (c) 2015 letvargo. All rights reserved.
//

import Cocoa

final class MainViewLogic {
    
    enum Knock { case Knock }
    
    private unowned var controller: MainViewController
    
    let srcKnock                    = Source<Knock>()
    let srcLightSwitch              = Source<Int>()
    let srcAtHome                   = Source<Int>()
    
    private let sKnockToShow        = Stream<Bool>()
    private let sLightToHide        = Stream<Bool>()
    private let sAtHomeToHide       = Stream<Bool>()
    
    private let cAtHome             = Cell(initialValue: true)
    private let cLightsOn           = Cell(initialValue: false)
    private let cShouldShowMessage  = Cell(initialValue: false)
    private let cMessage            = Cell(initialValue: "")
    
    private let oEnableLights       = Outlet<Bool>()
    private let oSetMessage         = Outlet<String>()
    
    init(controller: MainViewController) {
        self.controller = controller
        wire()
    }
    
    private func wire() {
        
        (
            [
                srcKnock        >-- (sKnockToShow, returnShow),
                srcLightSwitch  >-- (sLightToHide, returnHide),
                srcAtHome       >-- (sAtHomeToHide, returnHide)
            ]
                    --& cShouldShowMessage,
            
                srcAtHome
                    --^ (cAtHome, buttonStateToBool)
                        --< (oEnableLights, controller.setLightsEnabled),
            
                srcLightSwitch
                    --^ (cLightsOn, buttonStateToBool)
        )
                        --^ (cMessage, messageToShow)
                            --< (oSetMessage, controller.setMessage)
    }
}

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