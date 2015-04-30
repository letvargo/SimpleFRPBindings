# SimpleFRPBindings
Binding UI Elements with SimpleSwiftFRP

This is an example project that demonstrates how to use `SimpleSwiftFRP` as a substitute for traditional Cocoa bindings. It also demonstrates fairly clearly how `SimpleSwiftFRP` can help separate program logic from program state.

The application itself is nothing special. You knock by pressing a button. If no one is home, you get no response. If someone is home and the lights are off, you are told to go away. If someone is home and the lights are on, you are welcomed. The light switch is disabled when no one is home (cuz there's no one there to turn it on or off, right?), and the message is cleared with any action other than knocking, which causes the message to be shown.

Like I said, there's not a lot to it, but it provides a simple example of how the logic behind a user interface can be separated out from the state of the user interface, resulting in code that is clear, modular, and easily extendable.

It uses only two source files - `MainViewController.Swift` and `MainViewLogic.Swift`.

#### `The MainViewController` class

`MainViewController` is a subclass of `NSViewController`. The fact that all of the logic has been removed to the `MainViewLogic` class makes it slim. `@IBAction` methods are used to send a value to a `Source` in the `MainViewLogic` class. After the value has been processed, `MainViewLogic` calls one of the update methods in `MainViewController`. The result is a slimmed down view controller that just passes values and then updates UI elements as needed.

This is the entire `MainViewController` file:

    import Cocoa

    @NSApplicationMain
    final class MainViewController: NSViewController, NSApplicationDelegate {
        
        @IBOutlet weak var lightSwitch: NSButton!
        @IBOutlet weak var messageLabel: NSTextField!
        
        lazy var logic: MainViewLogic = {
            return MainViewLogic(controller: self)
        }()
    
        override func awakeFromNib() {
            logic.wire()
        }
        
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

As you can see, none of the `@IBAction` methods do anything other than send a value, and none of the "setter" methods (`setLightsEnabled` and `setMessage`) do anything other than update the UI. All of the logic is contained in...

#### The `MainViewLogic` class

`MainViewLogic` contains all of the logic for the view controller. To prevent any type of retain cycle, it keeps an unowned reference to the controller that is used by the `Outlet`s to call the "setter" methods in `MainViewController`.

    import SimpleSwiftFRP

    final class MainViewLogic {
        
        // A single-case enum that represents a knock on the door.
        enum Knock {
            case Knock
        }
        
        // An unowned reference to the view controller
        private unowned var controller: MainViewController
        
        // Declare and initialice the Sources. Note that there is one
        // Source for each control that will be sending a value.
        let srcKnock = Source<Knock>()
        let srcLightSwitch = Source<Int>()
        let srcAtHome = Source<Int>()
        
        // Declare and initialize the Streams
        private let sKnockToShow = Stream<Bool>()
        private let sLightToHide = Stream<Bool>()
        private let sAtHomeToHide = Stream<Bool>()
        
        // Declare and initialize the Cells
        private let cAtHome: Cell<Bool> = Cell(initialValue: true)
        private let cLightsOn: Cell<Bool> = Cell(initialValue: false)
        private let cShouldShowMessage: Cell<Bool> = Cell(initialValue: false)
        private let cMessage: Cell<String> = Cell(initialValue: "")
        
        // Declare and initialize the Outlets
        private let oEnableLights = Outlet<Bool>()
        private let oSetMessage = Outlet<String>()
        
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
    
    // The closures and functions defined below are used inside the wire() method.
    // By declaring them outside of the class and marking them private we are 
    // guaranteed that there will be no reference to any local state -
    // they operate on nothing other than the arguments passed to them.
    
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

By design, the two classes interact in only very specific ways. The `MainViewController` doesn't need to see any part of `MainViewLogic` other than the `Source`s that it sends values to. `MainViewLogic` doesn't need to see any part of `MainViewController` other than the two "setter" methods that it calls. The design is totally modular. You could rewrite the insides of either class without affecting the other as long as those few internal properties and functions maintained the same names.
