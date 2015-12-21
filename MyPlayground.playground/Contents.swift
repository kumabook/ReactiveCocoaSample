//: Playground - noun: a place where people can play

import XCPlayground
import Cocoa
import ReactiveCocoa
import Result
import Alamofire
import SwiftyJSON

enum ItemEvent {
    case ItemAdded(String)
    case ItemRemoved(String)
}

// Observer pattern

var pipe = Signal<ItemEvent, NSError>.pipe()

var itemSignal:   Signal<ItemEvent, NSError>          = pipe.0
var itemObserver: Signal<ItemEvent, NSError>.Observer = pipe.1

var items: [String] = []

itemSignal.observeNext { event in
    switch event {
    case .ItemAdded(let entry):
        print("entry added")
        items.append(entry)
    case .ItemRemoved(let entry):
        print("entry removed")
        items = items.filter { $0 != entry }
    }
}

var item1 = "item1"
var item2 = "item2"
var item3 = "item3"
itemObserver.sendNext(ItemEvent.ItemAdded(item1))
itemObserver.sendNext(ItemEvent.ItemAdded(item2))
itemObserver.sendNext(ItemEvent.ItemAdded(item3))

print("entry count: \(items.count)")
itemObserver.sendNext(ItemEvent.ItemRemoved(item1))
print("entry count: \(items.count)")


// api client like promise


func fetchLgtm() -> SignalProducer<String, NSError> {
    return SignalProducer<String, NSError> { (observer, disposable) in
        let url = "http://www.lgtm.in/g"
        let request = Manager.sharedInstance.request(.GET, url, headers: ["Accept":"application/json"])
        request.responseJSON(options: NSJSONReadingOptions()) { response in
            if let e = response.result.error {
                observer.sendFailed(e as NSError)
            } else {
                observer.sendNext(JSON(response.result.value!)["markdown"].stringValue)
                observer.sendCompleted()
            }
        }
        disposable.addDisposable({ request.cancel() })
    }

}

var signalProducer = fetchLgtm()

signalProducer.on(started: {
    }, failed: { error in
        print("failed \(error)")
    }, completed: {
        print("completed")
    }, interrupted: {
    }, terminated: {
    }, disposed: {
    }, next: { value in
        print("value \(value)")
    }).startOn(QueueScheduler()).start()


var signals: [SignalProducer<String, NSError>] = []

for i in 0..<3  {
    signals.append(fetchLgtm())
}

var multiSignal: SignalProducer<String, NSError> = signals.reduce(SignalProducer.empty, combine: { (currentSignal, nextSignal) in
    currentSignal.concat(nextSignal)
})


multiSignal.on(started: {
    }, failed: { error in
        print("failed \(error)")
    }, completed: {
        print("completed")
    }, interrupted: {
    }, terminated: {
    }, disposed: {
    }, next: { value in
        print("value \(value)")
}).startOn(QueueScheduler()).start()

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

