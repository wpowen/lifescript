import Foundation

func mergeBookCatalogs(manifest: [Book], generated: [Book]) -> [Book] {
    var merged = manifest
    var indexById = Dictionary(uniqueKeysWithValues: merged.enumerated().map { ($1.id, $0) })

    for book in generated {
        if let existingIndex = indexById[book.id] {
            merged[existingIndex] = book
        } else {
            indexById[book.id] = merged.count
            merged.append(book)
        }
    }

    return merged
}
