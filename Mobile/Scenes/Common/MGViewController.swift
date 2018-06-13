//
//  ViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/11/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

class MGViewController: UIViewController {

    // MARK: - Properties

    let wasPopped: Observable<Void>

    private let disposeBag = DisposeBag()
    internal let wasPoppedSubject = PublishSubject<Void>()

    // MARK: - Lifecycle

    init() {
        wasPopped = wasPoppedSubject.asObservable()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        //self.wasPopped = wasPoppedSubject.asObservable()
        //super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    //override func viewWillAppear(_ animated: Bool) {}

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        // ...
        setupConstraints()
    }

    private func setupConstraints() {
        //let guide: UILayoutGuide
        //if #available(iOS 11, *) {
        //    guide = view.safeAreaLayoutGuide
        //} else {
        //    guide = view.layoutMarginsGuide
        //}
        //let constraints = [
        //]
        //NSLayoutConstraint.activate(constraints)
    }

    private func setupBindings() {
        // ...
    }

}

// MARK: - PoppedObservable
extension MGViewController: PoppedObservable {

    func viewWasPopped() {
        wasPoppedSubject.onNext(())
    }

}
