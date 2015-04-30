////
////  ButtonLogic.swift
////  FRPBindingExample
////
////  Created by developer on 4/5/15.
////  Copyright (c) 2015 letvargo. All rights reserved.
////

import Cocoa

@NSApplicationMain
final class MainViewController: NSViewController, NSApplicationDelegate {
    
    @IBOutlet weak var lightSwitch: NSButton!
    @IBOutlet weak var messageLabel: NSTextField!
    
    lazy var logic: MainViewLogic = {
        return MainViewLogic(controller: self)
    }()
    
    @IBAction func sendAtHome(sender: AnyObject) {
        logic.srcAtHome.send(sender.state)
    }
    
    @IBAction func sendLightsOn(sender: AnyObject) {
        logic.srcLightSwitch.send(sender.state)
    }
    
    @IBAction func sendKnock(sender: AnyObject) {
        logic.srcKnock.send(.Knock)
    }
    
    func setLightsEnabled(value: Bool) {
        lightSwitch.enabled = value
    }
    
    func setMessage(value: String) {
        messageLabel.stringValue = value
    }
}