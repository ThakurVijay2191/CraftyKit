//
//  SwiftUIView.swift
//  
//
//  Created by Jagdeep Singh on 27/05/24.
//

import SwiftUI

@available(iOS 13.0, *)
struct AttributedLinkText: View {
//    var text: String = "By clicking the checkbox, you agree to our terms & conditions and privacy policy."
//    var links: [String] = ["terms & conditions", "privacy policy"]
    var text: String
    var links: [String]
    var textColor: Color
    var linkColor: Color
    var font: Font
    var showUnderline: Bool = false
    var onClick: (String)->()
    
    var body: some View {
        ChipLayout(alignment: .leading, spacing: 4){
            let list: [String] = text.components(separatedBy: " ")
            ForEach(list.indices, id: \.self){ index in
                Text(list[index])
                    .foregroundStyle(getLinkColor(index))
                    .font(font)
                    .underline(showUnderline ? showUnderline(index) : false, color: getLinkColor(index))
                    .contentShape(.rect)
                    .onTapGesture {
                        if isLink(index){
                            onClick(list[index])
                        }
                    }
            }
        }
    }
    
    func getLinkColor(_ index: Int)-> Color {
        let ranges = splitTextConsideringLinks(text, links)
        for range in ranges {
            if range.contains(index){
                return linkColor
            }
        }
        
        return textColor
    }
    
    func showUnderline(_ index: Int)-> Bool {
        let ranges = splitTextConsideringLinks(text, links)
        for range in ranges {
            if range.contains(index){
                return true
            }
        }
        
        return false
    }
    
    func isLink(_ index: Int)-> Bool {
        let ranges = splitTextConsideringLinks(text, links)
        for range in ranges {
            if range.contains(index){
                return true
            }
        }
        
        return false
    }
    
    func getClickedLink(_ text: String)-> String {
        if let index = links.firstIndex(where: { $0.contains(text.replacingOccurrences(of: ".", with: ""))}){
            return links[index]
        }
        
        return ""
    }
    
    func splitTextConsideringLinks(_ text: String, _ links: [String]) -> [ClosedRange<Array<String>.Index>] {
        let list: [String] = text.replacingOccurrences(of: ".", with: "").components(separatedBy: " ")
        var ranges: [ClosedRange<Array<String>.Index>] = []
        if links.count > 0 {
            for i in 0..<links.count {
                let link = links[i]
                let modifiedLink = link.components(separatedBy: " ")
                let firstOfModifiedLink = modifiedLink.first ?? ""
                if list.contains(firstOfModifiedLink){
                    if let index = list.firstIndex(of: firstOfModifiedLink){
                        let range = index...(index+(modifiedLink.count-1))
                        ranges.append(range)
                    }
                }
            }
        }
        return ranges
    }
}

#Preview {
    AttributedLinkText(text: "By clicking the checkbox, you agree to our terms & conditions and privacy policy.", links: ["terms & conditions", "privacy policy"], textColor: .brown, linkColor: .purple, font: .system(size: 20, weight: .bold), showUnderline: true) { clickedLink in
        
    }
}
