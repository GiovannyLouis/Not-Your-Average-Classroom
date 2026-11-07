//
//  TypingStatus.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//


enum TypingStatus {
    case loading    // the text is being generated
    case idle       // waiting for the first keystroke
    case running    // timer is counting down
    case finished   // text completed or time is up
}
