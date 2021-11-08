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
import Cartography
import WireCommonComponents

enum SettingsCellPreview {
    case none
    case text(String)
    case badge(Int)
    case image(UIImage)
    case color(UIColor)
}

protocol SettingsCellType: class {
    var titleText: String {get set}
    var preview: SettingsCellPreview {get set}
    var titleColor: UIColor {get set}
    var cellColor: UIColor? {get set}
    var descriptor: SettingsCellDescriptorType? {get set}
    var icon: StyleKitIcon? {get set}
}

class SettingsTableCell: UITableViewCell, SettingsCellType {
    let iconImageView = UIImageView()
    let cellNameLabel: UILabel = {
        let label = UILabel()
        label.font = .normalLightFont
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        return label
    }()

    let valueLabel: UILabel = {
        let valueLabel = UILabel()

        valueLabel.textColor = .lightGray
        valueLabel.font = UIFont.systemFont(ofSize: 17)
        valueLabel.textAlignment = .right

        return valueLabel
    }()

    let badge = RoundedBadge(view: UIView())
    var badgeLabel = UILabel()
    let imagePreview = UIImageView()
    private let separatorLine = UIView()
    private let topSeparatorLine = UIView()
    private lazy var cellNameLabelToIconInset: NSLayoutConstraint = cellNameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 24)

    var variant: ColorSchemeVariant? = .none {
        didSet {
            switch variant {
            case .dark?, .none:
                titleColor = .white
            case .light?:
                titleColor = UIColor.from(scheme: .textForeground, variant: .light)
            }
        }
    }

    var titleText: String = "" {
        didSet {
            cellNameLabel.text = titleText
        }
    }

    var preview: SettingsCellPreview = .none {
        didSet {
            switch preview {
            case .text(let string):
                valueLabel.text = string
                badgeLabel.text = ""
                badge.isHidden = true
                imagePreview.image = .none
                imagePreview.backgroundColor = UIColor.clear
                imagePreview.accessibilityValue = nil
                imagePreview.isAccessibilityElement = false

            case .badge(let value):
                valueLabel.text = ""
                badgeLabel.text = "\(value)"
                badge.isHidden = false
                imagePreview.image = .none
                imagePreview.backgroundColor = UIColor.clear
                imagePreview.accessibilityValue = nil
                imagePreview.isAccessibilityElement = false

            case .image(let image):
                valueLabel.text = ""
                badgeLabel.text = ""
                badge.isHidden = true
                imagePreview.image = image
                imagePreview.backgroundColor = UIColor.clear
                imagePreview.accessibilityValue = "image"
                imagePreview.isAccessibilityElement = true

            case .color(let color):
                valueLabel.text = ""
                badgeLabel.text = ""
                badge.isHidden = true
                imagePreview.image = .none
                imagePreview.backgroundColor = color
                imagePreview.accessibilityValue = "color"
                imagePreview.isAccessibilityElement = true

            case .none:
                valueLabel.text = ""
                badgeLabel.text = ""
                badge.isHidden = true
                imagePreview.image = .none
                imagePreview.backgroundColor = UIColor.clear
                imagePreview.accessibilityValue = nil
                imagePreview.isAccessibilityElement = false
            }
        }
    }

    var icon: StyleKitIcon? = nil {
        didSet {
            if let icon = icon {
                iconImageView.setIcon(icon, size: .tiny, color: UIColor.white)
                cellNameLabelToIconInset.isActive = true
            } else {
                iconImageView.image = nil
                cellNameLabelToIconInset.isActive = false
            }
        }
    }

    var isFirst: Bool = false {
        didSet {
            topSeparatorLine.isHidden = !isFirst
        }
    }

    var titleColor: UIColor = .white {
        didSet {
            cellNameLabel.textColor = titleColor
        }
    }

    var cellColor: UIColor? {
        didSet {
            backgroundColor = cellColor
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateBackgroundColor()
    }

    var descriptor: SettingsCellDescriptorType?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
        setupAccessibiltyElements()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        preview = .none
    }

    func setup() {
        backgroundColor = .clear
        backgroundView = UIView()
        selectedBackgroundView = UIView()

        iconImageView.contentMode = .center
        contentView.addSubview(iconImageView)

        [iconImageView].prepareForLayout()
        NSLayoutConstraint.activate([
          iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
          iconImageView.widthAnchor.constraint(equalToConstant: 16),
          iconImageView.heightAnchor.constraint(equalTo: iconImageView.heightAnchor),
          iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        cellNameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        contentView.addSubview(cellNameLabel)

        let leadingConstraint = cellNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        leadingConstraint.priority = .defaultHigh

        [cellNameLabel, iconImageView].prepareForLayout()
        NSLayoutConstraint.activate([
          cellNameLabelToIconInset,
            leadingConstraint,
          cellNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
          cellNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        cellNameLabelToIconInset.isActive = false

        valueLabel.textColor = UIColor.lightGray
        valueLabel.font = UIFont.systemFont(ofSize: 17)
        valueLabel.textAlignment = .right

        contentView.addSubview(valueLabel)

        badgeLabel.font = FontSpec(.small, .medium).font
        badgeLabel.textAlignment = .center
        badgeLabel.textColor = .black

        badge.containedView.addSubview(badgeLabel)

        badge.backgroundColor = .white
        badge.isHidden = true
        contentView.addSubview(badge)

        let trailingBoundaryView = accessoryView ?? contentView

        [cellNameLabel, valueLabel, badge].prepareForLayout()

        if trailingBoundaryView != contentView {
            [trailingBoundaryView].prepareForLayout()
        }

        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -8),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cellNameLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: trailingBoundaryView.trailingAnchor, constant: -16),
            badge.centerXAnchor.constraint(equalTo: valueLabel.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            badge.heightAnchor.constraint(equalToConstant: 20),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 28)
        ])

        [badge, badgeLabel].prepareForLayout()
        NSLayoutConstraint.activate([
            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -6),
            badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor),
            badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor)
        ])

        imagePreview.clipsToBounds = true
        imagePreview.layer.cornerRadius = 12
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.accessibilityIdentifier = "imagePreview"
        contentView.addSubview(imagePreview)

        constrain(contentView, imagePreview) { contentView, imagePreview in
            imagePreview.width == imagePreview.height
            imagePreview.height == 24
            imagePreview.trailing == contentView.trailing - 16
            imagePreview.centerY == contentView.centerY
        }

        separatorLine.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        separatorLine.isAccessibilityElement = false
        addSubview(separatorLine)

        constrain(self, separatorLine, cellNameLabel) { selfView, separatorLine, cellNameLabel in
            separatorLine.leading == cellNameLabel.leading
            separatorLine.trailing == selfView.trailing
            separatorLine.bottom == selfView.bottom
            separatorLine.height == .hairline
        }

        topSeparatorLine.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        topSeparatorLine.isAccessibilityElement = false
        addSubview(topSeparatorLine)

        constrain(self, topSeparatorLine, cellNameLabel) { selfView, topSeparatorLine, cellNameLabel in
            topSeparatorLine.leading == cellNameLabel.leading
            topSeparatorLine.trailing == selfView.trailing
            topSeparatorLine.top == selfView.top
            topSeparatorLine.height == .hairline
        }

        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        variant = .none
    }

    func setupAccessibiltyElements() {
        var currentElements = accessibilityElements ?? []
        currentElements.append(contentsOf: [cellNameLabel, valueLabel, imagePreview])
        accessibilityElements = currentElements
    }

    func updateBackgroundColor() {
        if cellColor != nil {
            return
        }

        if isHighlighted && selectionStyle != .none {
            backgroundColor = UIColor(white: 0, alpha: 0.2)
            badge.backgroundColor = UIColor.white
            badgeLabel.textColor = UIColor.black
        }
        else {
            backgroundColor = UIColor.clear
        }
    }
}

final class SettingsGroupCell: SettingsTableCell {
    override func setup() {
        super.setup()
        accessoryType = .disclosureIndicator
    }
}

final class SettingsButtonCell: SettingsTableCell {
    override func setup() {
        super.setup()
        cellNameLabel.textColor = UIColor.accent()
    }
}

final class SettingsToggleCell: SettingsTableCell {
    var switchView: UISwitch!

    override func setup() {
        super.setup()

        selectionStyle = .none
        shouldGroupAccessibilityChildren = false
        let switchView = UISwitch(frame: CGRect.zero)
        switchView.addTarget(self, action: #selector(SettingsToggleCell.onSwitchChanged(_:)), for: .valueChanged)
        accessoryView = switchView
        switchView.isAccessibilityElement = true

        accessibilityElements = [cellNameLabel, switchView]

        self.switchView = switchView
    }

    @objc
    func onSwitchChanged(_ sender: UIResponder) {
        descriptor?.select(SettingsPropertyValue(switchView.isOn))
    }
}

final class SettingsValueCell: SettingsTableCell {
    override var descriptor: SettingsCellDescriptorType? {
        willSet {
            if let propertyDescriptor = descriptor as? SettingsPropertyCellDescriptorType {
                NotificationCenter.default.removeObserver(self,
                                                          name: propertyDescriptor.settingsProperty.propertyName.notificationName,
                                                          object: nil)
            }
        }
        didSet {
            if let propertyDescriptor = descriptor as? SettingsPropertyCellDescriptorType {

                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(SettingsValueCell.onPropertyChanged(_:)),
                                                       name: propertyDescriptor.settingsProperty.propertyName.notificationName,
                                                       object: nil)
            }
        }
    }

    // MARK: - Properties observing

    @objc func onPropertyChanged(_ notification: Notification) {
        descriptor?.featureCell(self)
    }
}

final class SettingsTextCell: SettingsTableCell, UITextFieldDelegate {
    var textInput: UITextField!

    override func setup() {
        super.setup()
        selectionStyle = .none

        textInput = TailEditingTextField(frame: CGRect.zero)
        textInput.delegate = self
        textInput.textAlignment = .right
        textInput.textColor = UIColor.lightGray
        textInput.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        textInput.isAccessibilityElement = true

        contentView.addSubview(textInput)

        createConstraints()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onCellSelected(_:)))
        contentView.addGestureRecognizer(tapGestureRecognizer)
    }

    private func createConstraints() {
        let textInputSpacing: CGFloat = 16

        let trailingBoundaryView = accessoryView ?? contentView

        [textInput].prepareForLayout()
        if trailingBoundaryView != contentView {
            [trailingBoundaryView].prepareForLayout()
        }

        NSLayoutConstraint.activate([
            textInput.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -8),
            textInput.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            textInput.trailingAnchor.constraint(equalTo: trailingBoundaryView.trailingAnchor, constant: -textInputSpacing),

            cellNameLabel.trailingAnchor.constraint(equalTo: textInput.leadingAnchor, constant: -textInputSpacing)
        ])

    }

    override func setupAccessibiltyElements() {
        super.setupAccessibiltyElements()

        var currentElements = accessibilityElements ?? []
        if let textInput = textInput {
            currentElements.append(textInput)
        }
        accessibilityElements = currentElements
    }

    @objc
    func onCellSelected(_ sender: AnyObject!) {
        if !textInput.isFirstResponder {
            textInput.becomeFirstResponder()
        }
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacter(from: CharacterSet.newlines) != .none {
            textField.resignFirstResponder()
            return false
        }
        else {
            return true
        }
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textInput.text {
            descriptor?.select(SettingsPropertyValue.string(value: text))
        }
    }
}

final class SettingsStaticTextTableCell: SettingsTableCell {

    override func setup() {
        super.setup()
        cellNameLabel.numberOfLines = 0
        cellNameLabel.textAlignment = .justified
    }

}
