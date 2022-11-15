//
//  DiaryListDTO.swift
//  Segno
//
//  Created by Gordon Choi on 2022/11/15.
//

struct DiaryListDTO: Decodable {
    let data: [DiaryListItemDTO]
    
    #if DEBUG
    static let example = DiaryListDTO(data: [DiaryListItemDTO.exampleData])
    #endif
}

struct DiaryListItemDTO: Decodable {
    // TODO: 일단은 다이어리 리스트 아이템과 동일하게 작성. 이후 서버 사이드에 따라 바꾸겠습니다.
    let id: String
    let title: String
    let thumbnailPath: String
    
    #if DEBUG
    static let exampleData = DiaryListItemDTO(id: "asdf", title: "예시 데이터입니다.", thumbnailPath: "")
    #endif
}