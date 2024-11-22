//
//  PDFExport.swift
//  BTCMonteCarlo
//
//  Created by Conor on 22/11/2024.
//

import PDFKit
import AppKit

func saveResultsToPDF(results: [SimulationData], fileName: String) {
    let pdfDocument = PDFDocument()

    // Page dimensions
    let pageWidth: CGFloat = 612.0 // Standard US Letter width
    let pageHeight: CGFloat = 792.0 // Standard US Letter height
    let margin: CGFloat = 20.0

    // Font attributes for text
    let textAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 10)
    ]

    // Calculate the number of rows per page
    let lineHeight: CGFloat = "Test".size(withAttributes: textAttributes).height
    let usablePageHeight = pageHeight - 2 * margin
    let rowsPerPage = Int(usablePageHeight / lineHeight) - 2 // Subtract header and footer

    // Generate header row
    let header = "Week\tCycle Phase\tStarting BTC\tBTC Growth\tNet BTC Holdings\tBTC Price USD\tBTC Price EUR\tPortfolio Value EUR\tContribution EUR\tContribution Fee EUR\tNet Contribution BTC\tWithdrawal EUR\tPortfolio Pre-Withdrawal EUR\n"

    var currentPageContent = NSMutableAttributedString(string: header, attributes: textAttributes)
    var currentPageIndex = 0

    for (index, result) in results.enumerated() {
        // Append row content
        let row = "\(result.week)\t\(result.cyclePhase)\t\(result.startingBTC.formattedBTC())\t\(result.btcGrowth.formattedBTC())\t\(result.netBTCHoldings.formattedBTC())\t\(result.btcPriceUSD.formattedWithSeparator())\t\(result.btcPriceEUR.formattedWithSeparator())\t\(result.portfolioValueEUR.formattedWithSeparator())\t\(result.contributionEUR.formattedWithSeparator())\t\(result.contributionFeeEUR.formattedWithSeparator())\t\(result.netContributionBTC.formattedBTC())\t\(result.withdrawalEUR.formattedWithSeparator())\t\(result.portfolioPreWithdrawalEUR.formattedWithSeparator())\n"

        currentPageContent.append(NSAttributedString(string: row, attributes: textAttributes))

        // Check if the page is full or it's the last row
        if (index + 1) % rowsPerPage == 0 || index == results.count - 1 {
            // Render the current page
            if let pdfPage = createPDFPage(content: currentPageContent, pageRect: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), margin: margin) {
                pdfDocument.insert(pdfPage, at: currentPageIndex)
                currentPageIndex += 1
            }

            // Reset content for the next page
            currentPageContent = NSMutableAttributedString(string: header, attributes: textAttributes)
        }
    }

    // Present a save panel to the user
    #if os(macOS)
    let savePanel = NSSavePanel()
    savePanel.allowedFileTypes = ["pdf"]
    savePanel.nameFieldStringValue = "\(fileName).pdf"
    savePanel.title = "Save PDF"
    savePanel.canCreateDirectories = true

    savePanel.begin { (result) in
        if result == .OK, let url = savePanel.url {
            do {
                try pdfDocument.write(to: url)
                print("PDF saved to \(url.path)")
            } catch {
                print("Error saving PDF: \(error.localizedDescription)")
            }
        } else {
            print("Save cancelled or failed.")
        }
    }
    #else
    print("PDF export is only supported on macOS.")
    #endif
}

private func createPDFPage(content: NSAttributedString, pageRect: CGRect, margin: CGFloat) -> PDFPage? {
    // Create a new PDF page
    let pdfData = NSMutableData()
    var mediaBox = pageRect
    guard let consumer = CGDataConsumer(data: pdfData),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        print("Error creating PDF context")
        return nil
    }

    context.beginPDFPage(nil)
    context.saveGState()

    // Set up the text frame
    let textFrame = CGRect(x: margin, y: margin, width: pageRect.width - 2 * margin, height: pageRect.height - 2 * margin)

    // Flip the context coordinates
    context.translateBy(x: 0, y: pageRect.height)
    context.scaleBy(x: 1.0, y: -1.0)

    // Draw the attributed string
    let framesetter = CTFramesetterCreateWithAttributedString(content as CFAttributedString)
    let path = CGMutablePath()
    path.addRect(textFrame)
    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, content.length), path, nil)
    CTFrameDraw(frame, context)

    context.restoreGState()
    context.endPDFPage()
    context.closePDF()

    // Create a PDF document from the data
    return PDFDocument(data: pdfData as Data)?.page(at: 0)
}
