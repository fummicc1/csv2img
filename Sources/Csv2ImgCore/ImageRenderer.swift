import CoreGraphics
import CoreText
import Foundation

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

public class ImageRenderer {
    public func render(context: CGContext, _ representation: CsvImageRepresentation) -> CGImage? {
        let width = representation.width
        let height = representation.height

        context.setFillColor(representation.backgroundColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        context.setLineWidth(1)
        #if os(macOS)
            context.setStrokeColor(
                Color.separatorColor.cgColor
            )
        #elseif os(iOS)
            context.setStrokeColor(
                Color.separator.cgColor
            )
        #endif

        for column in representation.columns {
            context.move(to: CGPoint(x: column.frame.minX, y: 0))
            context.addLine(to: CGPoint(x: Int(column.frame.minX), y: height))
        }
        context.move(to: CGPoint(x: width, y: 0))
        context.addLine(to: CGPoint(x: width, y: height))

        for row in representation.rows {
            let y = Int(row.frames.first?.minY ?? 0)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: width, y: y))
        }
        context.move(to: CGPoint(x: 0, y: height))
        context.addLine(to: CGPoint(x: width, y: height))

        context.strokePath()

        #if os(macOS)
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1.0, y: -1.0)
        #endif

        for column in representation.columns {
            drawText(
                context: context, text: column.name, frame: column.frame, style: column.style,
                fontSize: representation.fontSize)
        }

        for row in representation.rows {
            for (index, (value, frame)) in zip(row.values, row.frames).enumerated() {
                let column = representation.columns[index]
                drawText(
                    context: context, text: value, frame: frame, style: column.style,
                    fontSize: representation.fontSize)
            }
        }

        return context.makeImage()
    }

    private func drawText(
        context: CGContext, text: String, frame: CGRect, style: Csv.Column.Style, fontSize: CGFloat
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: text.getFont(ofSize: fontSize),
            .foregroundColor: style.displayableColor(),
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)

        let textSize = attributedString.size()

        let textRect = CGRect(
            x: frame.origin.x + (frame.width - textSize.width) / 2,
            y: frame.origin.y + (frame.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        context.saveGState()

        // テキストの描画位置を設定
        let textPath = CGPath(rect: textRect, transform: nil)
        context.addPath(textPath)
        context.clip()

        // テキストを描画
        #if os(macOS)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
            attributedString.draw(in: textRect)
            NSGraphicsContext.restoreGraphicsState()
        #else
            UIGraphicsPushContext(context)
            attributedString.draw(in: textRect)
            UIGraphicsPopContext()
        #endif

        context.restoreGState()
    }
}
