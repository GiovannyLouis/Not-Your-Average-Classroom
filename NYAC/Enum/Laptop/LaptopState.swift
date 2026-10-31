//
//  LaptopState.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//


/// Where the shared run stands.
enum LaptopState: Equatable {
    case preparing             // study text is being generated, the clock has not started yet
    case running               // the shared clock is counting down and input is accepted
    case won                   // every tab is done
    case lost                  // the clock ran out before every tab was done
}
