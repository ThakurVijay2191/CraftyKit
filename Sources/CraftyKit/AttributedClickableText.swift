//
//  SwiftUIView.swift
//  
//
//  Created by Jagdeep Singh on 27/05/24.
//

import SwiftUI
import UIKit

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

//MARK: Chip Layout API
@available(iOS 16.0, *)
public struct ChipLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 10
    
    public init(alignment: Alignment, spacing: CGFloat) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        
        let rows = generateRows(maxWidth, proposal, subviews)
        
        for (index, row) in rows.enumerated() {
            if index == (rows.count - 1) {
                height+=row.maxHeight(proposal)
            }else {
                height+=row.maxHeight(proposal) + spacing
            }
        }
        
        return .init(width: maxWidth, height: height)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        let maxWidth = bounds.width
        let rows = generateRows(maxWidth, proposal, subviews)
        
        for row in rows {
            //Changing Origin X Based on Alignments
            let leading: CGFloat = bounds.maxX - maxWidth
            let trailing = bounds.maxX - (row.reduce(CGFloat.zero) { partialResult, view in
                let width = view.sizeThatFits(proposal).width
                
                if view == row.last {
                    //No Spacing
                    return partialResult + width
                }
                //with spacing

                return partialResult + width + spacing
            })
            
            let center = (trailing + leading) / 2
            
            //Reset origin X to Zero for each row
            origin.x = (alignment == .leading ? leading : alignment == .trailing ? trailing : center)
            for view in row {
                let viewSize = view.sizeThatFits(proposal)
                view.place(at: origin, proposal: proposal)
                //Updating Origin
                origin.x += (viewSize.width + spacing)
            }
            
            //Updating Origin Y
            origin.y += (row.maxHeight(proposal) + spacing)
        }
        
    }
    
    public func generateRows(_ maxWidth: CGFloat, _ proposal: ProposedViewSize, _ subviews: Subviews)-> [[LayoutSubviews.Element]]{
        var row: [LayoutSubviews.Element] = []
        var rows: [[LayoutSubviews.Element]] = []
        
        var origin = CGRect.zero.origin
        
        
        for view in subviews {
            let viewSize = view.sizeThatFits(proposal)
            
            //Pushing to New Row
            if (origin.x + viewSize.width + spacing) > maxWidth {
                rows.append(row)
                row.removeAll()
                //Reseting X Origin since it needs to start from left to right
                origin.x = 0
                row.append(view)
                //Updating Origin x
                origin.x+=(viewSize.width + spacing)
            }else {
                //Adding Item to same row
                row.append(view)
                //Updating Origin x
                origin.x+=(viewSize.width + spacing)
            }
        }
        
        //checking for any exhaust row
        if !row.isEmpty {
            rows.append(row)
            row.removeAll()
        }
        
        return rows
        
    }
    
 
}

@available(iOS 16.0, *)
public extension [LayoutSubviews.Element] {
    func maxHeight(_ proposal: ProposedViewSize)-> CGFloat {
        return self.compactMap { view in
            return view.sizeThatFits(proposal).height
        }.max() ?? 0
    }
}
