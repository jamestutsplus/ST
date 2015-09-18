//
//  NoteInfo.swift
//  TestAVADUI
//
//  Created by James Tyner on 9/17/15.
//  Copyright © 2015 James Tyner. All rights reserved.
//

import Foundation


class NoteInfo {
    
    var frequency:Double!
    var note_name:String!
    init(theFrequency:Double, theNoteName:String){
        frequency = theFrequency
        note_name = theNoteName
    }
    
    func getFrequency()-> Double {
        return frequency
    }
    
    func getNoteName()-> String {
        return note_name
    }
}
