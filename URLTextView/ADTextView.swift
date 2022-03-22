//
//  ADTextView.swift
//  URLTextView
//
//  Created by Vinu David Jose on 30/06/21.
//

import UIKit

 class ADTextView: UITextView {

	override public init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	 override func awakeFromNib() {
		super.awakeFromNib()
		configureADTextView()
	}

	// Make sure configureADTextView is called inside interfacebuilder
	 override func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		configureADTextView()
	}

	// just an override for triggering configureADTextView
	override open var text: String? {
		didSet {
		configureADTextView()
		}
	}

    override var font: UIFont? {
        didSet {
            updateTypingAttributes()
        }
    }

	public var maximumCharecterLength = 400

    /// For setting typing attributes
    public var typingContentAttributes : [NSAttributedString.Key:Any]!

	private var shouldReplaceText = false

	private var selectedRangeData : NSRange?

	// Subclass ADTextView and override this function if you want to use easy custum controls in interface builder
	open func configureADTextView() {
		delegate = self
		updateTypingAttributes()
	}

	private func updateTypingAttributes() {
		typingContentAttributes = Dictionary(uniqueKeysWithValues:
												self.typingAttributes.map { key, value in (NSAttributedString.Key(key.rawValue), value)})
	}
	/// For converting the textview data in to html
	/// - Returns: html String
	public func getHTML() -> String? {
		if attributedText.length != .zero {
			return self.attributedText.toHtml()
		}
		return nil
	}

	/// To get selected text from the textview
	/// - Parameter completion: text and url data if any
	public func getCursorPointData(completion:((text:String,url:String)?) -> Void) {

		if let textRange = selectedTextRange {
			selectedRangeData = self.selectedRange
			if let selectedText = self.text(in:textRange), selectedText.isEmpty == false {
				shouldReplaceText = true
				let titlefield = selectedText
				var urlField = ""
				attributedText.enumerateAttribute(.link, in:selectedRange, options: []) { (value,_,_) in
					 if let url = value as? URL {
                        urlField = url.absoluteString
                    }
				}
				let result = (text:titlefield, url:urlField)
				completion(result)
			} else { shouldReplaceText = false
				completion(nil)
			}
		}
	}

	/// To setback the hyper link to the textview
	/// - Parameter hyperlink: contains text and url
	public func setHyperlink(text: String?, url: String?) {
		if let link = url, let name = text {

		let parentString = NSMutableAttributedString(attributedString: attributedText)
			let hyperLinkText = parentString.addHyperLink(urlString: link, in: name, substring: name, font: self.font)
			if shouldReplaceText == true, let range = self.selectedRangeData {
				textStorage.replaceCharacters(in:range, with: hyperLinkText)
			} else { self.insertAtTextViewCursor(attributedString: hyperLinkText)
			}
		}
	}

    func setHTMLText(_ text: String) {
        self.attributedText = text.html2AttributedString
    }

	/// To insert the text at the cursor point
	/// - Parameter attributedString: string with url
	fileprivate func insertAtTextViewCursor(attributedString: NSAttributedString) {
		// Exit if no selected text range
		guard let selectedRange = selectedTextRange else {
			return
		}
		// If here, insert <attributedString> at cursor
		let cursorIndex = offset(from: beginningOfDocument, to: selectedRange.start)
		let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
		mutableAttributedText.insert(attributedString, at: cursorIndex)
		attributedText = mutableAttributedText
	}

}

extension ADTextView : UITextViewDelegate {
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		/// To update the typing text attribute
		typingAttributes = typingContentAttributes
		return true
	}
}





