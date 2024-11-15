//
//  AnimationViewController.swift
//  AnimationVerifier
//
//  Created by Антон Красильников on 27.12.2022.
//

import Foundation
import INCR_UIExtensions
import Lottie

class AnimationViewController: ViewController {
    let url: URL

    init(url: URL) {
        self.url = url
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let animationView = LottieAnimationView()
    let closeButton = UIButton()

    override func setup() {
        view.backgroundColor = .black

        navigationItem.backButtonTitle = "close"

        view.addSubview(animationView)
        animationView.loopMode = .loop
        animationView.animation = LottieAnimation.filepath(url.path)

        view.addSubview(closeButton)
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        addOperationOnAppearance {
            self.animationView.play()
        }
    }

    @objc func close() {
        dismiss(animated: true)
    }

    override func setupSizes() {
        animationView.autoCenterInSuperview()
        if let animation = animationView.animation {
            let size = animation.size

            if size.width < UIScreen.main.bounds.size.width, size.height < UIScreen.main.bounds.size.height {
                animationView.autoSetDimensions(to: size)
            }else if size.width >= size.height {
                animationView.autoMatch(.width, to: .width, of: view)
                animationView.autoMatch(.height, to: .width, of: animationView, withMultiplier: size.height/size.width)
            }else{
                animationView.autoMatch(.height, to: .height, of: view)
                animationView.autoMatch(.height, to: .width, of: animationView, withMultiplier: size.height/size.width)
            }
        }

        closeButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)
        closeButton.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        closeButton.autoSetDimensions(to: .init(width: 100, height: 40))
    }
}
