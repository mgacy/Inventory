//
//  ModalOrderKeypadViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/17/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import RxSwift
import RxCocoa

/// TODO: define protocol specifying any dimensions required for constraints:
// - width of detailview controller
// - height of navbar?
protocol ModalKeypadPresenting: class {
    var frame: CGRect { get }
}

class ModalOrderKeypadViewController: UIViewController {

    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: nil)
    let disposeBag = DisposeBag()
    var dismissalEvents: Observable<Void> {
        return Observable.of(
            barView.dismissChevron.rx.tap.mapToVoid(),
            tapGestureRecognizer.rx.event.mapToVoid()
        )
            .merge()
    }

    // MARK: Subviews
    private var keypadViewController: OrderKeypadViewController!
    private lazy var barView: ModalOrderBarView = {
        let view = ModalOrderBarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        return view
    }()

    // MARK: - Lifecycle

    /// TODO: pass primary view controller (or its constraints) to configure widths?
    init(keypadViewController: OrderKeypadViewController) {
        self.keypadViewController = keypadViewController
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - View Methods

    private func setupView() {
        view.backgroundColor = UIColor.clear
        view.isOpaque = false

        view.addSubview(barView)
        view.addSubview(backgroundView)
        backgroundView.addGestureRecognizer(tapGestureRecognizer)
        backgroundView.isUserInteractionEnabled = true

        embedViewController()
    }

    private func embedViewController() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = view.safeAreaLayoutGuide
        } else {
            guide = view.layoutMarginsGuide
        }

        let constraints = [
            // Navbar
            barView.topAnchor.constraint(equalTo: guide.topAnchor),
            /// TODO: is this the best way to set the height?
            barView.heightAnchor.constraint(equalToConstant: 44),
            barView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62),
            barView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            // Keypad
            keypadViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62),
            keypadViewController.view.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            keypadViewController.view.topAnchor.constraint(equalTo: barView.bottomAnchor),
            keypadViewController.view.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            // backgroundView
            backgroundView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: keypadViewController.view.leadingAnchor, constant: 0),
            backgroundView.topAnchor.constraint(equalTo: guide.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ]
        add(keypadViewController, with: constraints)
    }

}

// MARK: - Navigation Bar-Like SubView

class ModalOrderBarView: UIView {

    var dismissChevron: ChevronButton = {
        let button = ChevronButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 38, height: 15))
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Methods

    private func setupView() {
        backgroundColor = .white
        addSubview(dismissChevron)
        setupConstraints()
    }

    private func setupConstraints() {
        /*
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = safeAreaLayoutGuide
        } else {
            guide = layoutMarginsGuide
        }
        */
        let constraints = [
            dismissChevron.widthAnchor.constraint(equalToConstant: 38),
            dismissChevron.heightAnchor.constraint(equalToConstant: 15),
            dismissChevron.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            dismissChevron.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
            //dismissChevron.topAnchor.constraint(equalTo: guide.topAnchor, constant: 10)
        ]
        NSLayoutConstraint.activate(constraints)
    }

}
