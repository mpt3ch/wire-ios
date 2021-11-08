//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit
import WireDataModel

final class AnimatedPenView: UIView {

    private let WritingAnimationKey = "writing"
    private let dots = UIImageView()
    private let pen = UIImageView()

    var isAnimating: Bool = false {
        didSet {
            pen.layer.speed = isAnimating ? 1 : 0
            pen.layer.beginTime = pen.layer.convertTime(CACurrentMediaTime(), from: nil)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let iconColor = UIColor.from(scheme: .textForeground)
        let backgroundColor = UIColor.from(scheme: .background)

        dots.setIcon(.typingDots, size: 8, color: iconColor)
        pen.setIcon(.pencil, size: 8, color: iconColor)
        pen.backgroundColor = backgroundColor
        pen.contentMode = .center

        addSubview(dots)
        addSubview(pen)

        setupConstraints()
        startWritingAnimation()

        pen.layer.speed = 0
        pen.layer.timeOffset = 2

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        startWritingAnimation()
    }

    func setupConstraints() {
        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          distribute(by: 2, horizontally: dots, pen) ~ .defaultHigh,

          dots.leftAnchor.constraint(equalTo: container.leftAnchor),
          dots.topAnchor.constraint(equalTo: container.topAnchor),
          dots.bottomAnchor.constraint(equalTo: container.bottomAnchor),

          pen.rightAnchor.constraint(equalTo: container.rightAnchor),
          pen.topAnchor.constraint(equalTo: container.topAnchor),
          pen.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    func startWritingAnimation() {

        let p1 = 7
        let p2 = 10
        let p3 = 13
        let moveX = CAKeyframeAnimation(keyPath: "position.x")
        moveX.values = [p1, p2, p2, p3, p3, p1]
        moveX.keyTimes = [0, 0.25, 0.35, 0.50, 0.75, 0.85]
        moveX.duration = 2
        moveX.repeatCount = Float.infinity

        pen.layer.add(moveX, forKey: WritingAnimationKey)
    }

    func stopWritingAnimation() {
        pen.layer.removeAnimation(forKey: WritingAnimationKey)
    }

    @objc func applicationDidBecomeActive(_ notification: Notification) {
        startWritingAnimation()
    }

}

final class TypingIndicatorView: UIView {

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .smallLightFont
        label.textColor = .from(scheme: .textPlaceholder)

        return label
    }()
    let animatedPen = AnimatedPenView()
    let container: UIView = {
        let view = UIView()
        view.backgroundColor = .from(scheme: .background)

        return view
    }()
    let expandingLine: UIView = {
        let view = UIView()
        view.backgroundColor = .from(scheme: .background)

        return view
    }()

    private var expandingLineWidth: NSLayoutConstraint?

    var typingUsers: [UserType] = [] {
        didSet {
            updateNameLabel()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(expandingLine)
        addSubview(container)
        container.addSubview(nameLabel)
        container.addSubview(animatedPen)

        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        container.layer.cornerRadius = container.bounds.size.height / 2
    }

    func setupConstraints() {
        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          container.topAnchor.constraint(equalTo: view.topAnchor),
          container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          container.leftAnchor.constraint(equalTo: view.leftAnchor),
          container.rightAnchor.constraint(equalTo: view.rightAnchor),

          distribute(by: 4, horizontally: animatedPen, nameLabel) ~ .defaultHigh,

          animatedPen.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 8),
          animatedPen.centerYAnchor.constraint(equalTo: container.centerYAnchor),

          nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
          nameLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4 ~ .defaultHigh),
          nameLabel.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -8),

          expandingLine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          expandingLine.centerYAnchor.constraint(equalTo: view.centerYAnchor),
          expandingLine.heightAnchor.constraint(equalToConstant: 1),
          expandingLineWidth = expandingLine.widthAnchor.constraint(equalToConstant: 0)
        ])
    }

    func updateNameLabel() {
        nameLabel.text = typingUsers.compactMap { $0.name?.uppercased(with: Locale.current) }.joined(separator: ", ")
    }

    func setHidden(_ hidden: Bool, animated: Bool, completion: Completion? = nil) {

        let collapseLine = { () -> Void in
            self.expandingLineWidth?.constant = 0
            self.layoutIfNeeded()
        }

        let expandLine = { () -> Void in
            self.expandingLineWidth?.constant = self.bounds.width
            self.layoutIfNeeded()
        }

        let showContainer = {
            self.container.alpha = 1
        }

        let hideContainer = {
            self.container.alpha = 0
        }

        if animated {
            if hidden {
                collapseLine()
                UIView.animate(withDuration: 0.15, animations: hideContainer) { _ in
                    completion?()
                }
            } else {
                animatedPen.isAnimating = false
                self.layoutSubviews()
                UIView.animate(easing: .easeInOutQuad, duration: 0.35, animations: expandLine)
                UIView.animate(easing: .easeInQuad,
                                  duration: 0.15,
                                  delayTime: 0.15,
                                  animations: showContainer, completion: { _ in
                    self.animatedPen.isAnimating = true
                    completion?()
                })
            }

        } else {
            if hidden {
                collapseLine()
                self.container.alpha = 0
            } else {
                expandLine()
                showContainer()
            }
            completion?()
        }
    }

}
