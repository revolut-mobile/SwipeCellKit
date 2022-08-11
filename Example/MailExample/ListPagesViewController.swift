//
//  ListPagesViewController.swift
//  MailExample
//
//  Created by Ilia Sedov on 10.08.2022.
//

import Foundation
import UIKit

final class ListPagesViewController: UIViewController {
    private var pagesDataSource: PagesDataSource!
    private var pagesViewController: UIPageViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        pagesDataSource = .init()
        pagesViewController = createPagesViewController()

        addChild(pagesViewController)
        pagesViewController.view.embedTo(parentView: view)
        pagesViewController.didMove(toParent: self)

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                barButtonSystemItem: .fastForward,
                target: self,
                action: #selector(showNext)
            ),
            UIBarButtonItem(
                barButtonSystemItem: .rewind,
                target: self,
                action: #selector(showPrev)
            )
        ]
    }

    @objc
    private func showPrev() {
        guard let currentController = pagesViewController.viewControllers?.first,
              let nextController = pagesDataSource.pageViewController(
                pagesViewController,
                viewControllerBefore: currentController
              )
        else { return }

        pagesViewController.setViewControllers(
            [nextController],
            direction: .reverse,
            animated: true,
            completion: nil
        )
    }

    @objc
    private func showNext() {
        guard let currentController = pagesViewController.viewControllers?.first,
              let nextController = pagesDataSource.pageViewController(
                pagesViewController,
                viewControllerAfter: currentController
              )
        else { return }

        pagesViewController.setViewControllers(
            [nextController],
            direction: .forward,
            animated: true,
            completion: nil
        )
    }

    private func createPagesViewController() -> UIPageViewController {
        let pagesController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 16]
        )
        pagesController.dataSource = pagesDataSource
        pagesController
            .setViewControllers(
                [pagesDataSource.initialController],
                direction: .forward,
                animated: false,
                completion: nil
            )
        return pagesController
    }
}

class PagesDataSource: NSObject, UIPageViewControllerDataSource {
    private let controllers: [UIViewController]

    private static func isListController(_ viewController: UIViewController) -> Bool {
        viewController is CustomMailCollectionViewController
    }

    private static func getListContentController() -> UIViewController {
        CustomMailCollectionViewController()
    }

    private static func getDummyController() -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .purple
        let caption = UILabel()
        caption.font = .preferredFont(forTextStyle: .caption1)
        caption.text = "Dummy"
        caption.textColor = .white
        caption.backgroundColor = .clear
        caption.embedTo(parentView: controller.view)
        return controller
    }

    override init() {
        controllers = [
            Self.getListContentController(),
            Self.getDummyController()
        ]
    }

    var initialController: UIViewController {
        controllers.first!
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        if Self.isListController(viewController) {
            return nil
        }
        return controllers.first
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        if Self.isListController(viewController) {
            return controllers.last
        }
        return nil
    }
}


extension UIView {
    func embedTo(parentView: UIView) {
        parentView.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor),
            bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
