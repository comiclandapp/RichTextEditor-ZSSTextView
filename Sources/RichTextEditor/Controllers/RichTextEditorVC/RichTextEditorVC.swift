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
import ZSSTextView

#if canImport(UIKit)
import UIKit

public typealias PlatformView = UIView
public typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit

public typealias PlatformView = NSView
public typealias PlatformColor = NSColor
#endif

public class RichTextEditorVC: UIViewController, UITextViewDelegate {

    var editorView: RichHTMLEditorView!
    var sourceView: ZSSTextView!
    var toolbarView: PlatformView!
    var editorLoaded: Bool = false
    var internalHTML: String?
    let margin: CGFloat = 8

    /// color to tint the toolbar items
    var toolbarItemTintColor: PlatformColor?
    
    var toolbarCurrentColorPicker: ToolbarAction?

    /// The HTML code that the editor view contains.
    @objc public var html: String {
        get {
            return editorView?.html ?? ""
        }
        set {
            internalHTML = newValue
            if editorLoaded {
                updateHTML()
            }
        }
    }

    @objc public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoder")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        toolbarItemTintColor = PlatformColor.init(named: "tintColor")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerKeyboardNotifications()
        configureButtons()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        createEditorView()
        createSourceView()
        createToolbarView()
    }

    func updateHTML() {
        if let html = internalHTML {
            editorView?.html = html
            sourceView?.text = html
        }
    }

    func configureButtons() {
        let ni = navigationItem
        ni.hidesBackButton = true

//        ni.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized, style: .plain, target: self, action: #selector(cancelAction))
//        ni.rightBarButtonItem = UIBarButtonItem(title: "Done".localized, style: .plain, target: self, action: #selector(doneAction))
        ni.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAction))
        ni.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneAction))
    }

    @objc func cancelAction() {

        view.snapshotView(afterScreenUpdates: true)
        navigationController?.popViewController(animated: true)
    }

    @objc func doneAction() {

        // make sure the notification happens on the main thread
        // wait a sec
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name("NewInfoAvailable"), object: self.editorView.html)
        }

        cancelAction()
    }

    // MARK: - Set up editor

    func createEditorView() {

        editorView = RichHTMLEditorView()

        if let cssURL = Bundle.main.url(forResource: "editor", withExtension: "css"), let css = try? String(contentsOf: cssURL) {
            editorView.injectAdditionalCSS(css)
        }
        editorView.translatesAutoresizingMaskIntoConstraints = false
        editorView.delegate = self
        editorView.isScrollEnabled = true
        editorView.webView.scrollView.keyboardDismissMode = .interactive
        editorView.isOpaque = false
        editorView.backgroundColor = .systemBackground

        view.addSubview(editorView)

        let g = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            editorView.topAnchor.constraint(equalTo: g.topAnchor, constant: margin),
            editorView.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -margin),
            editorView.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -margin),
            editorView.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: margin)
        ])
    }

    // MARK: - Set up source editor

    func createSourceView() {

        sourceView = ZSSTextView()

        sourceView.translatesAutoresizingMaskIntoConstraints = false
        sourceView.delegate = self
        sourceView.isHidden = true

        sourceView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sourceView.autoresizesSubviews = true
        sourceView.adjustsFontForContentSizeCategory = true

        sourceView.font = UIFont.preferredFont(forTextStyle: .subheadline)

        view.addSubview(sourceView)

        let g = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            sourceView.topAnchor.constraint(equalTo: g.topAnchor, constant: margin),
            sourceView.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -margin),
            sourceView.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -margin),
            sourceView.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: margin)
        ])
    }

    // MARK: - create toolbar views

    let kToolbarSpacing: CGFloat = -89

    let divider: PlatformView = {
        let v = PlatformView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .lightGray
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 1),
            v.heightAnchor.constraint(equalToConstant: 40)
        ])
        return v
    }()

    let scrollView: UIScrollView = {
        let v = UIScrollView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.showsHorizontalScrollIndicator = false
        v.contentInsetAdjustmentBehavior = .never
        return v
    }()

    let stackViewLeft: UIStackView = {
        let v = UIStackView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.axis = .horizontal
        v.spacing = 2
        v.layoutMargins = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        v.isLayoutMarginsRelativeArrangement = true
        return v
    }()

    let stackViewRight: UIStackView = {
        let v = UIStackView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.axis = .horizontal
        v.spacing = 2
        v.layoutMargins = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        v.isLayoutMarginsRelativeArrangement = true
        return v
    }()

    func createToolbarView() {

        let width = view.safeAreaLayoutGuide.layoutFrame.width

        toolbarView = PlatformView(frame: CGRect(x: 0,
                                                 y: 0,
                                                 width: width,
                                                 height: 44))
        toolbarView.backgroundColor = .systemGray6
//        toolbarView.alpha = 0.0

        setupAllButtons()

        addScrollView(to: toolbarView)
        addStackViewLeft(to: scrollView)

        addStackViewRight(to: toolbarView)

        editorView.inputAccessoryView = toolbarView
        sourceView.inputAccessoryView = toolbarView
    }

    private func addScrollView(to view: PlatformView) {

        view.addSubview(scrollView)

        let g = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: kToolbarSpacing),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addStackViewLeft(to view: UIScrollView) {

        view.addSubview(stackViewLeft)

        NSLayoutConstraint.activate([
            stackViewLeft.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackViewLeft.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackViewLeft.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func addStackViewRight(to view: PlatformView) {

        view.addSubview(stackViewRight)

        let g = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            stackViewRight.leadingAnchor.constraint(equalTo: g.trailingAnchor, constant: kToolbarSpacing),
            stackViewRight.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            stackViewRight.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupAllButtons() {

        for group in ToolbarAction.actionGroup {
            for action in group {

                let btn = createButton(action: action)

                if group == ToolbarAction.actionGroup.first {
                    stackViewLeft.addArrangedSubview(btn)
                }
                else {
                    stackViewRight.addArrangedSubview(btn)
                }
            }
            if group != ToolbarAction.actionGroup.last {
                stackViewRight.addArrangedSubview(divider)
            }
        }
    }

    private func createButton(action: ToolbarAction) -> UIButton {

        let btn = UIButton(configuration: .borderless())
        btn.translatesAutoresizingMaskIntoConstraints = false

        btn.setImage(action.icon,
                     for: .normal)
        btn.tag = action.rawValue
        btn.tintColor = toolbarItemTintColor
        btn.addTarget(self,
                      action: #selector(didTapToolbarButton),
                      for: .touchUpInside)

        NSLayoutConstraint.activate([
            btn.heightAnchor.constraint(equalToConstant: 40),
            btn.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        return btn
    }
}

