//
//  PresentMessage.swift
//     
//
//  Created by Vlad Soroka on 10/15/16.
//  Copyright © 2016    All rights reserved.
//

import UIKit
import RxSwift
import Alamofire
import StoreKit

struct DisplayMessage {
    let title: String
    let description: String
}

protocol CanPresentMessage {
    
    func presentError(error: Error)
    func presentErrorMessage(error: String)
    func presentMessage(message: DisplayMessage)
    
}

protocol CanPresentQuestions {
    
    func presentSaveAndExitQuestion(question: DisplayMessage) -> Observable<(save : Bool, exit : Bool)>
    func presentTextQuestion(question: DisplayMessage, buttonSuccessName : String) -> Observable<String>
    
    func presentOptions(title: String, options: [String]) -> Observable<Int>
    
}

extension CanPresentMessage {
    
    func presentErrorMessage(error: String) {
        presentMessage(message: DisplayMessage(title: "Error", description: error))
    }
    
    func presentError(error: Error) {
        
        if let e = error as? RRError, case .userCanceled = e {
            return
        }
        
        if let e = error as? RRError, case .generic(let message) = e {
            presentErrorMessage(error: message)
            return
        }
        
        presentErrorMessage(error: error.localizedDescription)
    }
}


extension UIViewController : CanPresentMessage {
    
    fileprivate func onLoadedView<T>(observable: Observable<T>) -> Observable<T> {
        
        if self.isViewLoaded {
            return observable.subscribeOn(MainScheduler.instance)
        }
        else {
            return rx.sentMessage(#selector(UIViewController.viewDidLoad))
                .flatMapLatest { _ in observable }
                .subscribeOn(MainScheduler.instance)
        }

    }
    
    func presentMessage(message: DisplayMessage) {
        
        let _ =
        onLoadedView(observable: Observable.just( message ))
            .subscribe( onNext: { [unowned self] m in
                self.showInfoMessage(withTitle: m.title,
                                     m.description)
            })
        
    }
    
}

extension UIViewController : CanPresentQuestions {
    
    
    func presentOptions(title: String, options: [String]) -> Observable<Int> {
        
        return Observable.create({ [unowned self] (subscriber) -> Disposable in
            
            self.showOptions(with: title,
                                options: options, style: .actionSheet,
                                positiveCallback: { (x) in
                                    subscriber.onNext(x)
                                    subscriber.onCompleted()
            }, negativeCallback: nil)
            
            return Disposables.create()
        })
        
    }
    
    func presentInfoMessage(message: DisplayMessage) -> Observable<Void> {
        
        return Observable.create({ (subscriber) -> Disposable in
        
            self.showInfoMessage(withTitle: message.title,
                                 message.description, "Ок", {
                                    subscriber.onNext(())
                                    subscriber.onCompleted()
            })
            
            return Disposables.create()
        })
        
    }
    
    
    func presentTextQuestion(question: DisplayMessage, buttonSuccessName : String = "Save") -> Observable<String> {
        
        return Observable.create({ [unowned self] (subscriber) -> Disposable in
            
            let alertController = UIAlertController(title: question.title,
                                                    message: question.description,
                                                    preferredStyle: .alert)
            
            let saveAction = UIAlertAction(title: buttonSuccessName, style: .default, handler: {
                alert -> Void in
                
                let firstTextField = alertController.textFields![0] as UITextField
                
                subscriber.onNext(firstTextField.text ?? "")
                subscriber.onCompleted()
            })
            
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "New value"
            }
            
            alertController.addAction(saveAction)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default) { [unowned self] _ in
                subscriber.onError(GenericError.userCanceled)
                self.dismiss(animated: true, completion: nil)
            })
            
            self.present(alertController, animated: true, completion: nil)
            
            return Disposables.create()
        })
        
        
    }
    
    func presentcChangePasvordForm(question : DisplayMessage) -> Observable<(String, String, String)> {
        
        return Observable.create({ [unowned self] (subscriber) -> Disposable in
            
            let alertController = UIAlertController(title: question.title,
                                                    message: question.description,
                                                    preferredStyle: .alert)
            
            
            let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
                alert -> Void in
                
                let first = alertController.textFields![0].text ?? ""
                let second = alertController.textFields![1].text ?? ""
                let third = alertController.textFields![2].text ?? ""
                
                subscriber.onNext( (first, second, third) )
                subscriber.onCompleted()
            })
            
            alertController.addTextField { (textField : UITextField!) -> Void in
                
                textField.placeholder = "Old password"
                textField.textAlignment = .center
                
            }
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "New password"
                textField.textAlignment = .center
            }
            
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "Confirm new password"
                textField.textAlignment = .center
            }
            
            
            alertController.addAction(saveAction)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default) { [unowned self] _ in
                subscriber.onError(GenericError.userCanceled)
                self.dismiss(animated: true, completion: nil)
            })
            
            self.present(alertController, animated: true, completion: nil)
            
            return Disposables.create()
        })
        
        
    }
    
    
    func presentConfirmQuestion(question: DisplayMessage,
                                negativeText: String = "No",
                                positiveText: String = "Yes") -> Observable<Bool> {
        
        let x: Observable<Bool> = Observable.create({ [unowned self] (subscriber) -> Disposable in
            
            self.showSimpleQuestionMessage(withTitle: question.title,
                                           question.description,
                                           negativeText: negativeText,
                                           positiveText: positiveText, {
                                            subscriber.onNext(true)
                                            subscriber.onCompleted()
                                            
            },
                                           {
                                            subscriber.onNext(false)
                                            subscriber.onCompleted()
                                            
            })
            
            return Disposables.create()
        })
        
        return onLoadedView(observable: x)
    }
    
    func presentSaveAndExitQuestion(question: DisplayMessage) -> Observable<(save : Bool, exit : Bool)>
    {
        return Observable.create({ [unowned self] (subscriber) -> Disposable in
            
            let alertController = UIAlertController(title: question.title,
                                                    message: question.description,
                                                    preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Exit", style: .default) { _ in
                subscriber.onNext((save: false, exit: true))
                subscriber.onCompleted()
            })
            
            alertController.addAction(UIAlertAction(title: "Don't Exit", style: .default) { _ in
                subscriber.onNext((save: false, exit: false))
                subscriber.onCompleted()
            })
            
            alertController.addAction(UIAlertAction(title: "Save and Exit", style: .default) { _ in
                subscriber.onNext((save: true, exit: true))
                subscriber.onCompleted()
            })
            
            self.present(alertController, animated: true, completion: nil)
            
            return Disposables.create()

        })
    }
    
}
