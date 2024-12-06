//
//  File.swift
//  RichTextEditor
//
//  Created by Antonio Montes on 12/5/24.
//

import Foundation

extension String {

    public func deleteHTMLTags() -> String {
        let str = self.replacingOccurrences(of: "<style>[^>]+</style>", with: "", options: .regularExpression, range: nil)
        return str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
