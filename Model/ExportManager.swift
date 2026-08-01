import Foundation

struct ExportManager {
    static func generateCSV(memories: [Memory], depoName: String) -> URL? {
        var csvString = "Tarih,Kelime 1,Kelime 2,Kelime 3,Not,Konum,Gorsel URL\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        for memory in memories {
            let date = formatter.string(from: memory.date)
            let note = memory.note.replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: ",", with: ";")
            let location = (memory.locationName ?? "").replacingOccurrences(of: ",", with: ";")
            
            let row = "\(date),\(memory.wordOne),\(memory.wordTwo),\(memory.wordThree),\(note),\(location),\(memory.imageURL ?? "")\n"
            csvString.append(row)
        }
        
        let fileName = "\(depoName.replacingOccurrences(of: " ", with: "_"))_Anilari.csv"
        let path = URL.documentsDirectory.appending(path: fileName)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("CSV oluşturulamadı: \(error)")
            return nil
        }
    }
}
