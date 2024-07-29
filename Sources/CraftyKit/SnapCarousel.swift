//
//  SwiftUIView.swift
//  
//
//  Created by Vijay Thakur on 31/05/24.
//

import SwiftUI

@available(iOS 17.0, *)
public struct MySnapCarousel<Content: View, T: Identifiable>: View {
    var spacing: CGFloat = 20
    var minScale: CGFloat = 0.5
    var height: CGFloat
    var horizontalPadding: CGFloat = 35
    var showIndicators: Bool = false
    @Binding var items: [T]
    @ViewBuilder var content: (Binding<T>)-> Content
    public var body: some View {
        GeometryReader{
            let size = $0.size
            ScrollView(.horizontal) {
                HStack(spacing: 20){
                    ForEach($items){ item in
                        content(item)
                            .containerRelativeFrame(.horizontal)
                            .frame(height: size.height)
                            .visualEffect { content, geometryProxy in
                                content
                                    .scaleEffect(
                                        y: yScale(using: geometryProxy)
                                    )
                            }
                    }
                }
                .scrollTargetLayout()
            }
        }
        .frame(height: height)
        .safeAreaPadding(.horizontal, horizontalPadding)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(showIndicators ? .visible : .hidden)
    }
    
    private func yScale(using proxy: GeometryProxy) -> Double {
        let itemMidX = proxy.frame(in: .scrollView).midX
        
        guard let scrollViewWidth = proxy.bounds(of: .scrollView)?.width else {
            return 0
        }
        
        let scrollViewMidX = scrollViewWidth / 2
        let distanceFromCenter = abs(scrollViewMidX - itemMidX)
        let itemWidth = proxy.size.width
        let percentageToMidX = 1 - (distanceFromCenter / (itemWidth - 20))
        let calculatedScale = ((1 - minScale) * percentageToMidX) + minScale
        return max(minScale, calculatedScale)
    }
}

@available(iOS 17.0, *)
struct MySnapCarouselExample: View {
    @State private var items: [MySnapItem] = [.init(color: .red), .init(color: .blue), .init(color: .green), .init(color: .yellow)]
    var body: some View {
        MySnapCarousel(minScale: 0.7, height: 400, items: $items) { _ in
            RoundedRectangle(cornerRadius: 20)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    MySnapCarouselExample()
}
 
@available(iOS 13.0, *)
struct MySnapItem: Identifiable {
    var id: String = UUID().uuidString
    var color: Color
}

//
//  SwiftUIView.swift
//
//
//  Created by Jagdeep Singh on 27/05/24.
//

import SwiftUI
import UIKit

@available(iOS 16.0, *)
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

@available(iOS 16.0, *)
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

@available(iOS 13.0.0, *)
public struct ExpandableText: View {

    @State private var isExpanded: Bool = false
    @State private var isTruncated: Bool = false

    @State private var intrinsicSize: CGSize = .zero
    @State private var truncatedSize: CGSize = .zero
    @State private var moreTextSize: CGSize = .zero
    
    private let text: String
    internal var font: Font = .body
    internal var color: Color = .primary
    internal var lineLimit: Int = 3
    internal var moreButtonText: String = "more"
    internal var moreButtonFont: Font?
    internal var moreButtonColor: Color = .accentColor
    internal var expandAnimation: Animation = .default
    internal var collapseEnabled: Bool = false
    internal var trimMultipleNewlinesWhenTruncated: Bool = true
    
    /**
     Initializes a new `ExpandableText` instance with the specified text string, trimmed of any leading or trailing whitespace and newline characters.
     - Parameter text: The initial text string to display in the `ExpandableText` view.
     - Returns: A new `ExpandableText` instance with the specified text string and trimming applied.
     */
    public init(_ text: String) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var body: some View {
        content
            .lineLimit(isExpanded ? nil : lineLimit)
            .applyingTruncationMask(size: moreTextSize, enabled: shouldShowMoreButton)
            .readSize { size in
                truncatedSize = size
                isTruncated = truncatedSize != intrinsicSize
            }
            .background(
                content
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .readSize { size in
                        intrinsicSize = size
                        isTruncated = truncatedSize != intrinsicSize
                    }
            )
            .background(
                Text(moreButtonText)
                    .font(moreButtonFont ?? font)
                    .hidden()
                    .readSize { moreTextSize = $0 }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if (isExpanded && collapseEnabled) ||
                     shouldShowMoreButton {
                    if expandAnimation == .default {
                        isExpanded.toggle()
                    }else {
                        withAnimation(expandAnimation) { isExpanded.toggle() }
                    }
                }
            }
            .modifier(OverlayAdapter(alignment: .trailingLastTextBaseline, view: {
                if shouldShowMoreButton {
                    Button {
                        if expandAnimation == .default {
                            isExpanded.toggle()
                        }else {
                            withAnimation(expandAnimation) { isExpanded.toggle() }
                        }
                    } label: {
                        Text(moreButtonText)
                            .font(moreButtonFont ?? font)
                            .foregroundColor(moreButtonColor)
                    }
                }
            }))
    }
    
    private var content: some View {
        Text(.init(
            trimMultipleNewlinesWhenTruncated
                ? (shouldShowMoreButton ? textTrimmingDoubleNewlines : text)
                : text
        ))
        .font(font)
        .foregroundColor(color)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shouldShowMoreButton: Bool {
        !isExpanded && isTruncated
    }
    
    private var textTrimmingDoubleNewlines: String {
        text.replacingOccurrences(of: #"\n\s*\n"#, with: "\n", options: .regularExpression)
    }
}

@available(iOS 13.0.0, *)
#Preview {
    ExpandableText("I am an iOS developer and i am going to build my own cocoapod or a swift package in which there any helping components, reuseable componentes, helping methods, and all many things, give me best and unique names to choose for my library")
}



@available(iOS 13.0, *)
internal struct OverlayAdapter<V: View>: ViewModifier {
    let alignment: Alignment
    let view: () -> V
    
    init(alignment: Alignment, @ViewBuilder view: @escaping () -> V) {
        self.alignment = alignment
        self.view = view
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.overlay(alignment: alignment, content: view)
        } else {
            content.overlay(view(), alignment: alignment)
        }
    }
}

@available(iOS 13.0, *)
private struct TruncationTextMask: ViewModifier {

    let size: CGSize
    let enabled: Bool
    
    @Environment(\.layoutDirection) private var layoutDirection

    func body(content: Content) -> some View {
        if enabled {
            content
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                        HStack(spacing: 0) {
                            Rectangle()
                            HStack(spacing: 0) {
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        Gradient.Stop(color: .black, location: 0),
                                        Gradient.Stop(color: .clear, location: 0.9)
                                    ]),
                                    startPoint: layoutDirection == .rightToLeft ? .trailing : .leading,
                                    endPoint: layoutDirection == .rightToLeft ? .leading : .trailing
                                )
                                .frame(width: size.width, height: size.height)

                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(width: size.width)
                            }
                        }.frame(height: size.height)
                    }
                )
        } else {
            content
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@available(iOS 13.0, *)
internal extension View {
    func applyingTruncationMask(size: CGSize, enabled: Bool) -> some View {
        modifier(TruncationTextMask(size: size, enabled: enabled))
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

@available(iOS 13.0, *)
internal extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}


@available(iOS 13.0.0, *)
public extension ExpandableText {
    
    /**
     Sets the font for the text in the `ExpandableText` instance.
     - Parameter font: The font to use for the text. Defaults to `body`
     - Returns: A new `ExpandableText` instance with the specified font applied.
     */
    func font(_ font: Font) -> Self {
        var copy = self
        copy.font = font
        return copy
    }
    
    /**
     Sets the foreground color for the text in the `ExpandableText` instance.
     - Parameter color: The foreground color to use for the text. Defaults to `primary`
     - Returns: A new `ExpandableText` instance with the specified foreground color applied.
     */
    func foregroundColor(_ color: Color) -> Self {
        var copy = self
        copy.color = color
        return copy
    }
    
    /**
     Sets the maximum number of lines to use for rendering the text in the `ExpandableText` instance.
     - Parameter limit: The maximum number of lines to use for rendering the text. Defaults to `3`
     - Returns: A new `ExpandableText` instance with the specified line limit applied.
     */
    func lineLimit(_ limit: Int) -> Self {
        var copy = self
        copy.lineLimit = limit
        return copy
    }
    
    /**
     Sets the text to use for the "show more" button in the `ExpandableText` instance.
     - Parameter moreText: The text to use for the "show more" button. Defaults to `more`
     - Returns: A new `ExpandableText` instance with the specified "show more" button text applied.
     */
    func moreButtonText(_ moreText: String) -> Self {
        var copy = self
        copy.moreButtonText = moreText
        return copy
    }
    
    /**
     Sets the font to use for the "show more" button in the `ExpandableText` instance.
     - Parameter font: The font to use for the "show more" button. Defaults to the same font as the text
     - Returns: A new `ExpandableText` instance with the specified "show more" button font applied.
     */
    func moreButtonFont(_ font: Font) -> Self {
        var copy = self
        copy.moreButtonFont = font
        return copy
    }
    
    /**
     Sets the color to use for the "show more" button in the `ExpandableText` instance.
     - Parameter color: The color to use for the "show more" button. Defaults to `accentColor`
     - Returns: A new `ExpandableText` instance with the specified "show more" button color applied.
     */
    func moreButtonColor(_ color: Color) -> Self {
        var copy = self
        copy.moreButtonColor = color
        return copy
    }
    
    /**
     Sets the animation to use when expanding the `ExpandableText` instance.
     - Parameter animation: The animation to use for the expansion. Defaults to `default`
     - Returns: A new `ExpandableText` instance with the specified expansion animation applied.
     */
    func expandAnimation(_ animation: Animation) -> Self {
        var copy = self
        copy.expandAnimation = animation
        return copy
    }
    
    /**
      Enables collapsing behavior by tapping on the text body when the state is expanded.
      - Parameter value: Whether or not to enable collapse functionality.
      - Returns: A new `ExpandableText` instance with the specified collapse ability applied.
      */
     func enableCollapse(_ value: Bool) -> Self {
         var copy = self
         copy.collapseEnabled = value
         return copy
     }
    
    /**
     Sets whether multiple consecutive newline characters should be trimmed when truncating the text in the `ExpandableText` instance.
     - Parameter value: A boolean value indicating whether to trim multiple consecutive newline characters. Defaults to `true`
     - Returns: A new `ExpandableText` instance with the specified trimming behavior applied.
     */
    func trimMultipleNewlinesWhenTruncated(_ value: Bool) -> Self {
        var copy = self
        copy.trimMultipleNewlinesWhenTruncated = value
        return copy
    }
}

@available(iOS 17.0, *)
extension View {
    @ViewBuilder
    func iOSAlert<Content: View>(isPresented: Binding<Bool>, content: @escaping ()->Content)-> some View {
        self
            .modifier(iOSAlertHelper(isPresented: isPresented, alertContent: content))
    }
}

@available(iOS 17.0, *)
fileprivate struct iOSAlertHelper<iOSContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @State private var animate: Bool = false
    @State private var showAlert: Bool = false
    @ViewBuilder var alertContent: ()-> iOSContent
    func body(content: Content) -> some View {
        content
            .animation(.snappy(duration: 0.35, extraBounce: 0.1), value: isPresented)
            .onChange(of: isPresented, { oldValue, newValue in
                print(isPresented)
                withAnimation(.snappy(duration: 0.35, extraBounce: 0.1), completionCriteria: .logicallyComplete) {
                    self.showAlert = isPresented
                    self.animate = isPresented
                } completion: {
                    self.animate = false
                }
            })
            .overlay(content: {
                if showAlert {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .contentShape(.rect)
                        .onTapGesture {
                            self.isPresented.toggle()
                        }
                }
            })
            .overlay {
                if showAlert {
                    alertContent()
                        .transition(.scale(scale: animate ? 1.15 : 1, anchor: .center))
                }
            }
    }
}

@available(iOS 13.0, *)
struct NavigationManager {
    static func popToRootView(animated: Bool = false) {
        findNavigationController(viewController: UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.rootViewController)?.popToRootViewController(animated: animated)
    }
    
    static func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }
        
        if let navigationController = viewController as? UITabBarController {
            return findNavigationController(viewController: navigationController.selectedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        for childViewController in viewController.children {
            return findNavigationController(viewController: childViewController)
        }
        
        return nil
    }
}
