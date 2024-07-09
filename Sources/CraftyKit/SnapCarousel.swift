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
