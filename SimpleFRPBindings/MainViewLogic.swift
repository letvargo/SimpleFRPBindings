//
//  ViewOptions.swift
//  FRPBindingExample
//
//  Created by developer on 4/7/15.
//  Copyright (c) 2015 letvargo. All rights reserved.
//

import SimpleSwiftFRP

class MainViewLogic {
    
    enum Knock {
        case Knock
    }
    
    let controller: MainViewController
    
    let srcKnock = Source<Knock>()
    let srcLightSwitch = Source<Int>()
    let srcAtHome = Source<Int>()
    
    let sKnockToShow = Stream<Bool>()
    let sLightToHide = Stream<Bool>()
    let sAtHomeToHide = Stream<Bool>()
    
    let cAtHome: Cell<Bool> = Cell(initialValue: true)
    let cLightsOn: Cell<Bool> = Cell(initialValue: false)
    let cShouldShowMessage: Cell<Bool> = Cell(initialValue: false)
    let cMessage: Cell<String> = Cell(initialValue: "")
    
    let oEnableLights = Outlet<Bool>()
    let oSetMessage = Outlet<String>()
    
    init(controller: MainViewController) {
        self.controller = controller
    }
    
    func wire() {
        
        srcLightSwitch
            --^ (cLightsOn, buttonStateToBool)
        
        srcAtHome
            --^ (cAtHome, buttonStateToBool)
            --< (oEnableLights, controller.setLightsEnabled)
        
        [
            srcKnock
                >-- (sKnockToShow, returnShow),
            srcLightSwitch
                >-- (sLightToHide, returnHide),
            srcAtHome
                >-- (sAtHomeToHide, returnHide)
        ]
                --& cShouldShowMessage
        
        (
            cShouldShowMessage,
            cAtHome,
            cLightsOn
        )
            --^ (cMessage, messageToShow)
            --< (oSetMessage, controller.setMessage)
    }
}

private let returnShow: MainViewLogic.Knock -> Bool = { _ in return true }
private let returnHide: Int -> Bool = { _ in return false }

private func buttonStateToBool(state: Int) -> Bool {
    if state == 1 {
        return true
    } else {
        return false
    }
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