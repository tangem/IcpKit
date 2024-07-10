//
//  SHA224Tests.swift
//  UnitTests
//
//  Created by Konstantinos Gaitanis on 19.04.23.
//

import XCTest
@testable import IcpKit

final class ICPCryptographyTests: XCTestCase {
    // test vectors generated using https://pi7.org/hash/sha224
    func testSHA224() throws {
        XCTAssertEqual(Cryptography.sha224(Data()).hex, "D14A028C2A3A2BC9476102BB288234C415A2B01F828EA62AC5B3E42F".lowercased())
        XCTAssertEqual(Cryptography.sha224("0".data(using: .utf8)!).hex, "dfd5f9139a820075df69d7895015360b76d0360f3d4b77a845689614")
        XCTAssertEqual(Cryptography.sha224("abcd".data(using: .utf8)!).hex, "a76654d8e3550e9a2d67a0eeb6c67b220e5885eddd3fde135806e601")
        XCTAssertEqual(Cryptography.sha224("./`~.?!@#$".data(using: .utf8)!).hex, "c30cf54e8acd816aa0ab041605279563175199d2661f8e7aae37fa1e")
        XCTAssertEqual(Cryptography.sha224("Lorem ipsum dolor sit amet, consectetur adipiscing elit".data(using: .utf8)!).hex, "ff40dac83c1c21b71126074ced5c2f6195b6c993b53394ffb2e75f43")
    }
    
    // test vectors generated using https://crccalc.com/
    func testCRC32() {
        XCTAssertEqual(Cryptography.crc32(Data()).hex, "00000000")
        XCTAssertEqual(Cryptography.crc32("0".data(using: .utf8)!).hex, "F4DBDF21".lowercased())
        XCTAssertEqual(Cryptography.crc32("abcd".data(using: .utf8)!).hex, "ED82CD11".lowercased())
        XCTAssertEqual(Cryptography.crc32("./`~.?!@#$".data(using: .utf8)!).hex, "77838090".lowercased())
        XCTAssertEqual(Cryptography.crc32("Lorem ipsum dolor sit amet, consectetur adipiscing elit".data(using: .utf8)!).hex, "6C8ADA71".lowercased())
    }
    
    // test vectors generated using keysmith https://github.com/dfinity/keysmith and following procedure
    // 1. generate public key from seed `./keysmith public-key`
    // 2. generate principal `./keysmith principal`
    // 3. a. Remove dashes from principal and make uppercase
    //    b. Base32 decode principal using https://cryptii.com/pipes/hex-to-base32
    //    c. remove first 4 bytes and last byte
    //    d. This is the hash of the serialized public key
    // 4. Serialize publicKey from 1 using ICPCrypto.serialiseDER
    // 5. Compare hash224 of publicKey with the one obtained at 3.d
    func testDerSerialiser() throws {
        XCTAssertEqual(try Cryptography.der(uncompressedEcPublicKey: Data.fromHex("046acf4c93dd993cd736420302eb70da254532ec3179250a21eec4ce823ff289aaa382cb19576b2c6447db09cb45926ebd69ce288b1804580fe62c343d3252ec6e")!).hex, "3056301006072a8648ce3d020106052b8104000a034200046acf4c93dd993cd736420302eb70da254532ec3179250a21eec4ce823ff289aaa382cb19576b2c6447db09cb45926ebd69ce288b1804580fe62c343d3252ec6e")
        
        XCTAssertEqual(try Cryptography.der(uncompressedEcPublicKey: Data.fromHex("04723cdc9bd653014a501159fb89dcc6e2cf03f242955b987b53dd6193815d8a9d4a4f5b902b2819d270c28f0710ad96fea5b13f5fe30c6e244bf2941ebf4ec36e")!).hex, "3056301006072a8648ce3d020106052b8104000a03420004723cdc9bd653014a501159fb89dcc6e2cf03f242955b987b53dd6193815d8a9d4a4f5b902b2819d270c28f0710ad96fea5b13f5fe30c6e244bf2941ebf4ec36e")
    }
    
    // test vectors from https://internetcomputer.org/docs/current/references/id-encoding-spec#test-vectors
    func testCanonicalText() {
        XCTAssertEqual(ICPCryptography.encodeCanonicalText(Data.fromHex("000102030405060708")!), "xtqug-aqaae-bagba-faydq-q")
        XCTAssertEqual(ICPCryptography.encodeCanonicalText(Data.fromHex("00")!), "2ibo7-dia")
        XCTAssertEqual(ICPCryptography.encodeCanonicalText(Data.fromHex("")!), "aaaaa-aa")
        XCTAssertEqual(ICPCryptography.encodeCanonicalText(Data.fromHex("0102030405060708091011121314151617181920212223242526272829")!), "iineg-fibai-bqibi-ga4ea-searc-ijrif-iwc4m-bsibb-eirsi-jjge4-ucs")
    }
    
    // test vectors generated using keysmith https://github.com/dfinity/keysmith
    // `./keysmith principal`
//    func testPrincipal() throws {
//        let principal1 = try ICPCryptography.selfAuthenticatingPrincipal(uncompressedPublicKey: testWallet1PublicKey)
//        XCTAssertEqual(principal1.string, "mi5lp-tjcms-b77vo-qbfgp-cjzyc-imkew-uowpv-ca7f4-l5fzx-yy6ba-qqe")
//        let principal2 = try ICPCryptography.selfAuthenticatingPrincipal(uncompressedPublicKey: testWallet2PublicKey)
//        XCTAssertEqual(principal2.string, "sxmip-mryjb-rjp3v-ol36n-miqtr-ji4i6-5k6h3-fdy2n-gz5lr-c2s6s-sqe")
//    }
//    
//    // test vectors generated using keysmith https://github.com/dfinity/keysmith
//    // `./keysmith account`
//    func testAccount() throws {
//        let principal1 = try ICPCryptography.selfAuthenticatingPrincipal(uncompressedPublicKey: testWallet1PublicKey)
//        let mainAccount1 = try ICPAccount.mainAccount(of: principal1)
//        XCTAssertEqual(mainAccount1.accountId.hex, "cafd0a2c27f41a851837b00f019b93e741f76e4147fe74435fb7efb836826a1c")
//        
//        let principal2 = try ICPCryptography.selfAuthenticatingPrincipal(uncompressedPublicKey: testWallet2PublicKey)
//        let mainAccount2 = try ICPAccount.mainAccount(of: principal2)
//        XCTAssertEqual(mainAccount2.accountId.hex, "6c14be31a1df0f5f061520e5d8e0c08bb3743a671ab4a3bb7b05743a8ca3c1f0")
//    }
    
    func testOrderIndependentHash() throws {
        let hash = { try ICPCryptography.orderIndependentHash($0) }
        XCTAssertEqual(try hash(0).base64EncodedString(), "bjQLnP+zepicpUTmu3gKLHiQHT+zNzh2hRGjBhevoB0=")
        XCTAssertEqual(try hash(624485).base64EncodedString(), "feIrCG+oMpxyE/8xmkTcLKgeI+6pn1/YvXIiLU/8tsI=")
        XCTAssertEqual(try hash("abcd").base64EncodedString(), "iNQmb9TmM40TuEX88olXnSCciXgjuSF9o+Fhk28DFYk=")
        XCTAssertEqual(try hash(Data([0x47, 0x98, 0xfd])).base64EncodedString(), "6aHlLhIiGuehu602UlJY0yLJa4O2mqHUSz5JCuDg4X0=")
        XCTAssertEqual(try hash([
            Data([0x47, 0x98, 0xfd]),
            Data([0x47, 0x98, 0xfd]),
        ]).base64EncodedString(), "PpjoUxKzZoOgTSezNZvEfnq0yClqvqXdJwcpYBgxLbg=")
        
        XCTAssertThrowsError(try hash(-1))
        
        XCTAssertEqual(try hash([
            "abcd": Data([0x47, 0x98, 0xfd]),
            "fngt": Data([0x47, 0x98, 0xfd]),
        ]).base64EncodedString(), "CxCF+O8wyQLiW2Dy18SkenGre+PaEtsrMptNi1fql/o=")
    }
}
