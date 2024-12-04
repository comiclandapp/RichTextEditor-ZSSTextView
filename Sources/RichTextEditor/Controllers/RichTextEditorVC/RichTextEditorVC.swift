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

import UIKit

import InfomaniakRichHTMLEditor
import ZSSTextView

public class RichTextEditorVC: UIViewController, UITextViewDelegate {
    
    public var okLocalizedText = "OK"
    public var cancelLocalizedText = "Cancel"
    public var doneLocalizedText = "Done"
    public var addLocalizedText = "Add"
    public var createLinkLocalizedText = "Create Link"
    public var textColorLocalizedText = "Text Color"
    public var backgroundColorLocalizedText = "Background Color"
    public var labelOptionalLocalizedText = "Label (Optional)"
    public var chooseFontLocalizedText = "Choose Font"
    public var chooseFontSizeLocalizedText = "Choose Font Size"
    public var chooseFontSizeBetweenLocalizedText = "Choose a font size between 1 and 7"
    
    /// color to tint the toolbar items
    public var toolbarItemTintColor: UIColor?

    var editorLoaded: Bool = false
    private var internalHTML: String?

    var toolbarCurrentColorPicker: ToolbarAction?
    
    // MARK: - create toolbar views
    
    let kToolbarSpacing: CGFloat = -89
    
    lazy var divider: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .lightGray
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 1),
            v.heightAnchor.constraint(equalToConstant: 40)
        ])
        return v
    }()
    
    lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.showsHorizontalScrollIndicator = false
        v.contentInsetAdjustmentBehavior = .never
        return v
    }()
    
    lazy var stackViewLeft: UIStackView = {
        let v = UIStackView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.axis = .horizontal
        v.spacing = 2
        v.layoutMargins = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        v.isLayoutMarginsRelativeArrangement = true
        return v
    }()
    
    lazy var stackViewRight: UIStackView = {
        let v = UIStackView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.axis = .horizontal
        v.spacing = 2
        v.layoutMargins = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        v.isLayoutMarginsRelativeArrangement = true
        return v
    }()
    
    lazy var editorView: RichHTMLEditorView = {
        
        let view = RichHTMLEditorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if let cssURL = Bundle.main.url(forResource: "editor", withExtension: "css"), let css = try? String(contentsOf: cssURL) {
            view.injectAdditionalCSS(css)
        }
        
        view.delegate = self
        view.isScrollEnabled = true
        view.webView.scrollView.keyboardDismissMode = .interactive
        view.isOpaque = false
        view.backgroundColor = .systemBackground
        
        return view
    }()

    lazy var sourceView: ZSSTextView = {
        
        let view = ZSSTextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.delegate = self
        view.isHidden = true
        
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.autoresizesSubviews = true
        view.adjustsFontForContentSizeCategory = true
        
        view.font = UIFont.preferredFont(forTextStyle: .subheadline)
        
        return view
    }()
    
    lazy var toolbarView: UIView = {

        let width = view.safeAreaLayoutGuide.layoutFrame.width

        let view = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: width,
                                        height: 44))
        view.backgroundColor = .systemGray6
        // view.alpha = 0.0

        return view
    }()

    /// The HTML code that the editor view contains.
    @objc public var html: String {
        get {
            return editorView.html
        }
        set {
            internalHTML = newValue
            if editorLoaded {
                setHTML()
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
        
        setupInternalViews()
        activateConstraints()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        registerKeyboardNotifications()
    }
    
    func setHTML() {
        
        if let html = internalHTML {
            editorView.html = html
            sourceView.text = html
        }
    }

    @objc func cancelAction() {
        
        view.snapshotView(afterScreenUpdates: true)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func doneAction() {

        // make sure the notification happens on the main thread
        DispatchQueue.main.async {
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name("NewInfoAvailable"),
                    object: self.html)
        }
        
        cancelAction()
    }
}

private extension RichTextEditorVC {

    private func setupInternalViews() {
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(editorView)
        view.addSubview(sourceView)

        createToolbarView()
        setupToolbarButtons()

        configureNavButtons()
    }

    private func activateConstraints() {
        
        let margins = view.safeAreaLayoutGuide
        let margin: CGFloat = 8
        
        NSLayoutConstraint.activate([
            editorView.topAnchor.constraint(equalTo: margins.topAnchor, constant: margin),
            editorView.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -margin),
            editorView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -margin),
            editorView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: margin),
            
            sourceView.topAnchor.constraint(equalTo: margins.topAnchor, constant: margin),
            sourceView.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -margin),
            sourceView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -margin),
            sourceView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: margin)
        ])
    }

    private func configureNavButtons() {
        
        let ni = navigationItem
        ni.hidesBackButton = true
        
        ni.leftBarButtonItem = UIBarButtonItem(title: cancelLocalizedText, style: .plain, target: self, action: #selector(cancelAction))
        ni.rightBarButtonItem = UIBarButtonItem(title: doneLocalizedText, style: .plain, target: self, action: #selector(doneAction))
    }
    
    private func createToolbarView() {

        addScrollView(to: toolbarView)
        addStackViewLeft(to: scrollView)

        addStackViewRight(to: toolbarView)

        editorView.inputAccessoryView = toolbarView
        sourceView.inputAccessoryView = toolbarView
    }

    private func addScrollView(to view: UIView) {

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

    private func addStackViewRight(to view: UIView) {

        view.addSubview(stackViewRight)

        let g = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            stackViewRight.leadingAnchor.constraint(equalTo: g.trailingAnchor, constant: kToolbarSpacing),
            stackViewRight.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            stackViewRight.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupToolbarButtons() {

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

