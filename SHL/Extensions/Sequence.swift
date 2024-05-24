//
//  Sequence.swift
//  SHL
//
//  Created by KibbeWater on 2024-05-24.
//

import Foundation

extension Sequence {
    func groupBy<T: Hashable>(keySelector: (Element) -> T) -> [T: [Element]] {
        return reduce(into: [:]) { result, element in
            let key = keySelector(element)
            result[key, default: []].append(element)
        }
    }
}
