//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

import InfomaniakRichHTMLEditor
import UIKit

// MARK: - Handle toolbar buttons

extension RichTextEditorVC {

    @objc func didTapToolbarButton(_ sender: UIButton) {
 
        guard let action = ToolbarAction(rawValue: sender.tag) else {
            return
        }

        switch action {
            case .bold:
                editorView.bold()
            case .italic:
                editorView.italic()
            case .underline:
                editorView.underline()
            case .strikethrough:
                editorView.strikethrough()
            case .link:
                handleLink()
            case .toggleSubscript:
                editorView.toggleSubscript()
            case .toggleSuperscript:
                editorView.toggleSuperscript()
            case .orderedList:
                editorView.orderedList()
            case .unorderedList:
                editorView.unorderedList()
            case .justifyFull:
                editorView.justify(.full)
            case .justifyLeft:
                editorView.justify(.left)
            case .justifyCenter:
                editorView.justify(.center)
            case .justifyRight:
                editorView.justify(.right)

            case .fontName:
                presentFontNameAlert()
            case .fontSize:
                presentFontSizeAlert()

            case .foregroundColor:
                presentColorPicker(title: textColorLocalizedText, action: .foregroundColor)
            case .backgroundColor:
                presentColorPicker(title: backgroundColorLocalizedText, action: .backgroundColor)

            case .outdent:
                editorView.outdent()
            case .indent:
                editorView.indent()

            case .undo:
                editorView.undo()
            case .redo:
                editorView.redo()
            case .removeFormat:
                editorView.removeFormat()

            case .showSource:
                showHTMLSource(sender)
            case .dismissKeyboard:
                _ = editorView.resignFirstResponder()
                _ = sourceView.resignFirstResponder()
        }
    }

    private func enableToolbarItems(_ enable: Bool = true) {

        for element in stackViewLeft.arrangedSubviews {
            guard let button = element as? UIButton else {
                continue
            }
            button.isEnabled = enable
        }
    }

    private func showHTMLSource(_ sender: UIButton) {

        if sourceView.isHidden {

            editorView.isHidden = true
            enableToolbarItems(false)

            sourceView.text = editorView.html
            sourceView.isHidden = false
        }
        else {
            sourceView.isHidden = true
            enableToolbarItems()

            editorView.html = sourceView.text
            editorView.isHidden = false
        }
    }

    private func handleLink() {

        if editorView.selectedTextAttributes.hasLink {
            editorView.unlink()
        }
        else {
            presentCreateLinkAlert()
        }
    }

    private func presentCreateLinkAlert() {

        let alertController = UIAlertController(title: createLinkLocalizedText,
                                                message: nil,
                                                preferredStyle: .alert)

        alertController.addTextField { nameTextField in
            nameTextField.placeholder = self.labelOptionalLocalizedText
        }
        alertController.addTextField { urlTextField in
            urlTextField.placeholder = "URL"
            urlTextField.keyboardType = .URL
        }

        alertController.addAction(UIAlertAction(title: addLocalizedText, style: .default) { _ in
            guard let rawURL = alertController.textFields?[1].text,
                  let url = URL(string: rawURL)
            else { return }

            self.editorView.addLink(url: url,
                                    text: alertController.textFields?[0].text)
        })
        alertController.addAction(UIAlertAction(title: cancelLocalizedText, style: .cancel) { _ in
            _ = self.editorView.becomeFirstResponder()
        })

        present(alertController, animated: true)
    }

    private func presentFontNameAlert() {

        let alertController = UIAlertController(title: chooseFontLocalizedText,
                                                message: nil,
                                                preferredStyle: .actionSheet)
/*
 cell.textLabel.text = @"Default";
 cell.textLabel.font = [UIFont fontWithName:@"ArialMT" size:fontSize];
 cell.textLabel.text = @"Trebuchet";
 cell.textLabel.font = [UIFont fontWithName:@"TrebuchetMS" size:fontSize];
 cell.textLabel.text = @"Verdana";
 cell.textLabel.font = [UIFont fontWithName:@"Verdana" size:fontSize];
 cell.textLabel.text = @"Georgia";
 cell.textLabel.font = [UIFont fontWithName:@"Georgia" size:fontSize];
 cell.textLabel.text = @"Palatino";
 cell.textLabel.font = [UIFont fontWithName:@"Palatino-Roman" size:fontSize];
 break;
 cell.textLabel.text = @"Times New Roman";
 cell.textLabel.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:fontSize];
 cell.textLabel.text = @"Courier New";
 cell.textLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:fontSize];
 */
        let fontOptions = ["-apple-system",
//                           "ArialMT",
                           "TrebuchetMS",
                           "Verdana",
                           "Georgia",
                           "Palatino-Roman",
                           "TimesNewRomanPSMT",
                           "CourierNewPSMT",
                           "serif",
                           "sans-serif"]
//                           "Savoye Let"]
        for fontOption in fontOptions {
            alertController.addAction(UIAlertAction(title: fontOption, style: .default) { _ in
                self.editorView.setFontName(fontOption)
            })
        }
        alertController.addAction(UIAlertAction(title: cancelLocalizedText,
                                                style: .cancel))

        present(alertController, animated: true)
    }

    private func presentFontSizeAlert() {

        let alertController = UIAlertController(
            title: chooseFontSizeLocalizedText,
            message: chooseFontSizeBetweenLocalizedText,
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
            if let fontSize = self.editorView.selectedTextAttributes.fontSize {
                textField.text = "\(fontSize)"
            }
        }

        alertController.addAction(UIAlertAction(title: okLocalizedText,
                                                style: .default) { _ in
            guard let text = alertController.textFields?[0].text, let newSize = Int(text) else { return }
            self.editorView.setFontSize(newSize)
        })
        alertController.addAction(UIAlertAction(title: cancelLocalizedText,
                                                style: .cancel))

        present(alertController, animated: true)
    }

    private func presentColorPicker(title: String,
                                    action: ToolbarAction) {

        let vc = UIColorPickerViewController()

        vc.title = title
        vc.supportsAlpha = false
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        vc.popoverPresentationController?.sourceItem = stackViewLeft.arrangedSubviews[action.rawValue]

        toolbarCurrentColorPicker = action

        present(vc, animated: true)
    }
}

// MARK: - UIColorPickerViewControllerDelegate

extension RichTextEditorVC: UIColorPickerViewControllerDelegate {

    public func colorPickerViewController(_ viewController: UIColorPickerViewController,
                                   didSelect color: UIColor,
                                   continuously: Bool) {

        guard let toolbarCurrentColorPicker else {
            return
        }

        if toolbarCurrentColorPicker == .foregroundColor {
            editorView.setForegroundColor(viewController.selectedColor)
        }
        else if toolbarCurrentColorPicker == .backgroundColor {
            editorView.setBackgroundColor(viewController.selectedColor)
        }
    }

    public func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        toolbarCurrentColorPicker = nil
    }
}

extension RichTextEditorVC {

    /// Register for keyboard willHide willShow notifications
    func registerKeyboardNotifications() {

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc func keyboardNotification(notification: NSNotification) {

        if editorView.isHidden {
            if let userInfo = notification.userInfo {

                let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
                let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
                let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
                let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
                let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)

                if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                    // hide keyboard

                    sourceView.contentInset = .zero
                }
                else {
                    // show keyboard
                    let kbHeight: CGFloat = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)!.size.height
                    sourceView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: kbHeight + 44, right: 0)
                    sourceView.scrollIndicatorInsets = sourceView.contentInset
                    let selectedRange = sourceView.selectedRange
                    sourceView.scrollRangeToVisible(selectedRange)
                }

                UIView.animate(withDuration: duration,
                               delay: TimeInterval(0),
                               options: animationCurve,
                               animations: { self.view.layoutIfNeeded() },
                               completion: nil)
            }
        }
    }
}
