import XCTest

@testable import SwiftNumbersCore

final class CellReferenceMatrixTests: XCTestCase {
  private func assertCellReferenceRoundTrip(
    _ a1: String,
    row: Int,
    column: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    let uppercase = a1.uppercased()
    let parsed = try CellReference(a1)
    XCTAssertEqual(parsed.address.row, row, file: file, line: line)
    XCTAssertEqual(parsed.address.column, column, file: file, line: line)
    XCTAssertEqual(parsed.a1, uppercase, file: file, line: line)

    let rebuilt = CellReference(address: CellAddress(row: row, column: column))
    XCTAssertEqual(rebuilt.a1, uppercase, file: file, line: line)
  }

  func testCellReferenceRoundTripMatrix0001() throws {
    try assertCellReferenceRoundTrip("A1", row: 0, column: 0)
  }

  func testCellReferenceRoundTripMatrix0002() throws {
    try assertCellReferenceRoundTrip("N8", row: 7, column: 13)
  }

  func testCellReferenceRoundTripMatrix0003() throws {
    try assertCellReferenceRoundTrip("AA15", row: 14, column: 26)
  }

  func testCellReferenceRoundTripMatrix0004() throws {
    try assertCellReferenceRoundTrip("AN22", row: 21, column: 39)
  }

  func testCellReferenceRoundTripMatrix0005() throws {
    try assertCellReferenceRoundTrip("BA29", row: 28, column: 52)
  }

  func testCellReferenceRoundTripMatrix0006() throws {
    try assertCellReferenceRoundTrip("BN36", row: 35, column: 65)
  }

  func testCellReferenceRoundTripMatrix0007() throws {
    try assertCellReferenceRoundTrip("CA43", row: 42, column: 78)
  }

  func testCellReferenceRoundTripMatrix0008() throws {
    try assertCellReferenceRoundTrip("L50", row: 49, column: 11)
  }

  func testCellReferenceRoundTripMatrix0009() throws {
    try assertCellReferenceRoundTrip("Y57", row: 56, column: 24)
  }

  func testCellReferenceRoundTripMatrix0010() throws {
    try assertCellReferenceRoundTrip("AL64", row: 63, column: 37)
  }

  func testCellReferenceRoundTripMatrix0011() throws {
    try assertCellReferenceRoundTrip("AY71", row: 70, column: 50)
  }

  func testCellReferenceRoundTripMatrix0012() throws {
    try assertCellReferenceRoundTrip("BL78", row: 77, column: 63)
  }

  func testCellReferenceRoundTripMatrix0013() throws {
    try assertCellReferenceRoundTrip("BY85", row: 84, column: 76)
  }

  func testCellReferenceRoundTripMatrix0014() throws {
    try assertCellReferenceRoundTrip("J92", row: 91, column: 9)
  }

  func testCellReferenceRoundTripMatrix0015() throws {
    try assertCellReferenceRoundTrip("W99", row: 98, column: 22)
  }

  func testCellReferenceRoundTripMatrix0016() throws {
    try assertCellReferenceRoundTrip("AJ106", row: 105, column: 35)
  }

  func testCellReferenceRoundTripMatrix0017() throws {
    try assertCellReferenceRoundTrip("AW113", row: 112, column: 48)
  }

  func testCellReferenceRoundTripMatrix0018() throws {
    try assertCellReferenceRoundTrip("BJ120", row: 119, column: 61)
  }

  func testCellReferenceRoundTripMatrix0019() throws {
    try assertCellReferenceRoundTrip("BW127", row: 126, column: 74)
  }

  func testCellReferenceRoundTripMatrix0020() throws {
    try assertCellReferenceRoundTrip("H134", row: 133, column: 7)
  }

  func testCellReferenceRoundTripMatrix0021() throws {
    try assertCellReferenceRoundTrip("U141", row: 140, column: 20)
  }

  func testCellReferenceRoundTripMatrix0022() throws {
    try assertCellReferenceRoundTrip("AH148", row: 147, column: 33)
  }

  func testCellReferenceRoundTripMatrix0023() throws {
    try assertCellReferenceRoundTrip("AU155", row: 154, column: 46)
  }

  func testCellReferenceRoundTripMatrix0024() throws {
    try assertCellReferenceRoundTrip("BH162", row: 161, column: 59)
  }

  func testCellReferenceRoundTripMatrix0025() throws {
    try assertCellReferenceRoundTrip("BU169", row: 168, column: 72)
  }

  func testCellReferenceRoundTripMatrix0026() throws {
    try assertCellReferenceRoundTrip("F176", row: 175, column: 5)
  }

  func testCellReferenceRoundTripMatrix0027() throws {
    try assertCellReferenceRoundTrip("S183", row: 182, column: 18)
  }

  func testCellReferenceRoundTripMatrix0028() throws {
    try assertCellReferenceRoundTrip("AF190", row: 189, column: 31)
  }

  func testCellReferenceRoundTripMatrix0029() throws {
    try assertCellReferenceRoundTrip("AS197", row: 196, column: 44)
  }

  func testCellReferenceRoundTripMatrix0030() throws {
    try assertCellReferenceRoundTrip("BF4", row: 3, column: 57)
  }

  func testCellReferenceRoundTripMatrix0031() throws {
    try assertCellReferenceRoundTrip("BS11", row: 10, column: 70)
  }

  func testCellReferenceRoundTripMatrix0032() throws {
    try assertCellReferenceRoundTrip("D18", row: 17, column: 3)
  }

  func testCellReferenceRoundTripMatrix0033() throws {
    try assertCellReferenceRoundTrip("Q25", row: 24, column: 16)
  }

  func testCellReferenceRoundTripMatrix0034() throws {
    try assertCellReferenceRoundTrip("AD32", row: 31, column: 29)
  }

  func testCellReferenceRoundTripMatrix0035() throws {
    try assertCellReferenceRoundTrip("AQ39", row: 38, column: 42)
  }

  func testCellReferenceRoundTripMatrix0036() throws {
    try assertCellReferenceRoundTrip("BD46", row: 45, column: 55)
  }

  func testCellReferenceRoundTripMatrix0037() throws {
    try assertCellReferenceRoundTrip("BQ53", row: 52, column: 68)
  }

  func testCellReferenceRoundTripMatrix0038() throws {
    try assertCellReferenceRoundTrip("B60", row: 59, column: 1)
  }

  func testCellReferenceRoundTripMatrix0039() throws {
    try assertCellReferenceRoundTrip("O67", row: 66, column: 14)
  }

  func testCellReferenceRoundTripMatrix0040() throws {
    try assertCellReferenceRoundTrip("AB74", row: 73, column: 27)
  }

  func testCellReferenceRoundTripMatrix0041() throws {
    try assertCellReferenceRoundTrip("AO81", row: 80, column: 40)
  }

  func testCellReferenceRoundTripMatrix0042() throws {
    try assertCellReferenceRoundTrip("BB88", row: 87, column: 53)
  }

  func testCellReferenceRoundTripMatrix0043() throws {
    try assertCellReferenceRoundTrip("BO95", row: 94, column: 66)
  }

  func testCellReferenceRoundTripMatrix0044() throws {
    try assertCellReferenceRoundTrip("CB102", row: 101, column: 79)
  }

  func testCellReferenceRoundTripMatrix0045() throws {
    try assertCellReferenceRoundTrip("M109", row: 108, column: 12)
  }

  func testCellReferenceRoundTripMatrix0046() throws {
    try assertCellReferenceRoundTrip("Z116", row: 115, column: 25)
  }

  func testCellReferenceRoundTripMatrix0047() throws {
    try assertCellReferenceRoundTrip("AM123", row: 122, column: 38)
  }

  func testCellReferenceRoundTripMatrix0048() throws {
    try assertCellReferenceRoundTrip("AZ130", row: 129, column: 51)
  }

  func testCellReferenceRoundTripMatrix0049() throws {
    try assertCellReferenceRoundTrip("BM137", row: 136, column: 64)
  }

  func testCellReferenceRoundTripMatrix0050() throws {
    try assertCellReferenceRoundTrip("BZ144", row: 143, column: 77)
  }

  func testCellReferenceRoundTripMatrix0051() throws {
    try assertCellReferenceRoundTrip("K151", row: 150, column: 10)
  }

  func testCellReferenceRoundTripMatrix0052() throws {
    try assertCellReferenceRoundTrip("X158", row: 157, column: 23)
  }

  func testCellReferenceRoundTripMatrix0053() throws {
    try assertCellReferenceRoundTrip("AK165", row: 164, column: 36)
  }

  func testCellReferenceRoundTripMatrix0054() throws {
    try assertCellReferenceRoundTrip("AX172", row: 171, column: 49)
  }

  func testCellReferenceRoundTripMatrix0055() throws {
    try assertCellReferenceRoundTrip("BK179", row: 178, column: 62)
  }

  func testCellReferenceRoundTripMatrix0056() throws {
    try assertCellReferenceRoundTrip("BX186", row: 185, column: 75)
  }

  func testCellReferenceRoundTripMatrix0057() throws {
    try assertCellReferenceRoundTrip("I193", row: 192, column: 8)
  }

  func testCellReferenceRoundTripMatrix0058() throws {
    try assertCellReferenceRoundTrip("V200", row: 199, column: 21)
  }

  func testCellReferenceRoundTripMatrix0059() throws {
    try assertCellReferenceRoundTrip("AI7", row: 6, column: 34)
  }

  func testCellReferenceRoundTripMatrix0060() throws {
    try assertCellReferenceRoundTrip("AV14", row: 13, column: 47)
  }

  func testCellReferenceRoundTripMatrix0061() throws {
    try assertCellReferenceRoundTrip("BI21", row: 20, column: 60)
  }

  func testCellReferenceRoundTripMatrix0062() throws {
    try assertCellReferenceRoundTrip("BV28", row: 27, column: 73)
  }

  func testCellReferenceRoundTripMatrix0063() throws {
    try assertCellReferenceRoundTrip("G35", row: 34, column: 6)
  }

  func testCellReferenceRoundTripMatrix0064() throws {
    try assertCellReferenceRoundTrip("T42", row: 41, column: 19)
  }

  func testCellReferenceRoundTripMatrix0065() throws {
    try assertCellReferenceRoundTrip("AG49", row: 48, column: 32)
  }

  func testCellReferenceRoundTripMatrix0066() throws {
    try assertCellReferenceRoundTrip("AT56", row: 55, column: 45)
  }

  func testCellReferenceRoundTripMatrix0067() throws {
    try assertCellReferenceRoundTrip("BG63", row: 62, column: 58)
  }

  func testCellReferenceRoundTripMatrix0068() throws {
    try assertCellReferenceRoundTrip("BT70", row: 69, column: 71)
  }

  func testCellReferenceRoundTripMatrix0069() throws {
    try assertCellReferenceRoundTrip("E77", row: 76, column: 4)
  }

  func testCellReferenceRoundTripMatrix0070() throws {
    try assertCellReferenceRoundTrip("R84", row: 83, column: 17)
  }

  func testCellReferenceRoundTripMatrix0071() throws {
    try assertCellReferenceRoundTrip("AE91", row: 90, column: 30)
  }

  func testCellReferenceRoundTripMatrix0072() throws {
    try assertCellReferenceRoundTrip("AR98", row: 97, column: 43)
  }

  func testCellReferenceRoundTripMatrix0073() throws {
    try assertCellReferenceRoundTrip("BE105", row: 104, column: 56)
  }

  func testCellReferenceRoundTripMatrix0074() throws {
    try assertCellReferenceRoundTrip("BR112", row: 111, column: 69)
  }

  func testCellReferenceRoundTripMatrix0075() throws {
    try assertCellReferenceRoundTrip("C119", row: 118, column: 2)
  }

  func testCellReferenceRoundTripMatrix0076() throws {
    try assertCellReferenceRoundTrip("P126", row: 125, column: 15)
  }

  func testCellReferenceRoundTripMatrix0077() throws {
    try assertCellReferenceRoundTrip("AC133", row: 132, column: 28)
  }

  func testCellReferenceRoundTripMatrix0078() throws {
    try assertCellReferenceRoundTrip("AP140", row: 139, column: 41)
  }

  func testCellReferenceRoundTripMatrix0079() throws {
    try assertCellReferenceRoundTrip("BC147", row: 146, column: 54)
  }

  func testCellReferenceRoundTripMatrix0080() throws {
    try assertCellReferenceRoundTrip("BP154", row: 153, column: 67)
  }

  func testCellReferenceRoundTripMatrix0081() throws {
    try assertCellReferenceRoundTrip("A161", row: 160, column: 0)
  }

  func testCellReferenceRoundTripMatrix0082() throws {
    try assertCellReferenceRoundTrip("N168", row: 167, column: 13)
  }

  func testCellReferenceRoundTripMatrix0083() throws {
    try assertCellReferenceRoundTrip("AA175", row: 174, column: 26)
  }

  func testCellReferenceRoundTripMatrix0084() throws {
    try assertCellReferenceRoundTrip("AN182", row: 181, column: 39)
  }

  func testCellReferenceRoundTripMatrix0085() throws {
    try assertCellReferenceRoundTrip("BA189", row: 188, column: 52)
  }

  func testCellReferenceRoundTripMatrix0086() throws {
    try assertCellReferenceRoundTrip("BN196", row: 195, column: 65)
  }

  func testCellReferenceRoundTripMatrix0087() throws {
    try assertCellReferenceRoundTrip("CA3", row: 2, column: 78)
  }

  func testCellReferenceRoundTripMatrix0088() throws {
    try assertCellReferenceRoundTrip("L10", row: 9, column: 11)
  }

  func testCellReferenceRoundTripMatrix0089() throws {
    try assertCellReferenceRoundTrip("Y17", row: 16, column: 24)
  }

  func testCellReferenceRoundTripMatrix0090() throws {
    try assertCellReferenceRoundTrip("AL24", row: 23, column: 37)
  }

  func testCellReferenceRoundTripMatrix0091() throws {
    try assertCellReferenceRoundTrip("AY31", row: 30, column: 50)
  }

  func testCellReferenceRoundTripMatrix0092() throws {
    try assertCellReferenceRoundTrip("BL38", row: 37, column: 63)
  }

  func testCellReferenceRoundTripMatrix0093() throws {
    try assertCellReferenceRoundTrip("BY45", row: 44, column: 76)
  }

  func testCellReferenceRoundTripMatrix0094() throws {
    try assertCellReferenceRoundTrip("J52", row: 51, column: 9)
  }

  func testCellReferenceRoundTripMatrix0095() throws {
    try assertCellReferenceRoundTrip("W59", row: 58, column: 22)
  }

  func testCellReferenceRoundTripMatrix0096() throws {
    try assertCellReferenceRoundTrip("AJ66", row: 65, column: 35)
  }

  func testCellReferenceRoundTripMatrix0097() throws {
    try assertCellReferenceRoundTrip("AW73", row: 72, column: 48)
  }

  func testCellReferenceRoundTripMatrix0098() throws {
    try assertCellReferenceRoundTrip("BJ80", row: 79, column: 61)
  }

  func testCellReferenceRoundTripMatrix0099() throws {
    try assertCellReferenceRoundTrip("BW87", row: 86, column: 74)
  }

  func testCellReferenceRoundTripMatrix0100() throws {
    try assertCellReferenceRoundTrip("H94", row: 93, column: 7)
  }

  func testCellReferenceRoundTripMatrix0101() throws {
    try assertCellReferenceRoundTrip("U101", row: 100, column: 20)
  }

  func testCellReferenceRoundTripMatrix0102() throws {
    try assertCellReferenceRoundTrip("AH108", row: 107, column: 33)
  }

  func testCellReferenceRoundTripMatrix0103() throws {
    try assertCellReferenceRoundTrip("AU115", row: 114, column: 46)
  }

  func testCellReferenceRoundTripMatrix0104() throws {
    try assertCellReferenceRoundTrip("BH122", row: 121, column: 59)
  }

  func testCellReferenceRoundTripMatrix0105() throws {
    try assertCellReferenceRoundTrip("BU129", row: 128, column: 72)
  }

  func testCellReferenceRoundTripMatrix0106() throws {
    try assertCellReferenceRoundTrip("F136", row: 135, column: 5)
  }

  func testCellReferenceRoundTripMatrix0107() throws {
    try assertCellReferenceRoundTrip("S143", row: 142, column: 18)
  }

  func testCellReferenceRoundTripMatrix0108() throws {
    try assertCellReferenceRoundTrip("AF150", row: 149, column: 31)
  }

  func testCellReferenceRoundTripMatrix0109() throws {
    try assertCellReferenceRoundTrip("AS157", row: 156, column: 44)
  }

  func testCellReferenceRoundTripMatrix0110() throws {
    try assertCellReferenceRoundTrip("BF164", row: 163, column: 57)
  }

  func testCellReferenceRoundTripMatrix0111() throws {
    try assertCellReferenceRoundTrip("BS171", row: 170, column: 70)
  }

  func testCellReferenceRoundTripMatrix0112() throws {
    try assertCellReferenceRoundTrip("D178", row: 177, column: 3)
  }

  func testCellReferenceRoundTripMatrix0113() throws {
    try assertCellReferenceRoundTrip("Q185", row: 184, column: 16)
  }

  func testCellReferenceRoundTripMatrix0114() throws {
    try assertCellReferenceRoundTrip("AD192", row: 191, column: 29)
  }

  func testCellReferenceRoundTripMatrix0115() throws {
    try assertCellReferenceRoundTrip("AQ199", row: 198, column: 42)
  }

  func testCellReferenceRoundTripMatrix0116() throws {
    try assertCellReferenceRoundTrip("BD6", row: 5, column: 55)
  }

  func testCellReferenceRoundTripMatrix0117() throws {
    try assertCellReferenceRoundTrip("BQ13", row: 12, column: 68)
  }

  func testCellReferenceRoundTripMatrix0118() throws {
    try assertCellReferenceRoundTrip("B20", row: 19, column: 1)
  }

  func testCellReferenceRoundTripMatrix0119() throws {
    try assertCellReferenceRoundTrip("O27", row: 26, column: 14)
  }

  func testCellReferenceRoundTripMatrix0120() throws {
    try assertCellReferenceRoundTrip("AB34", row: 33, column: 27)
  }

  func testCellReferenceRoundTripMatrix0121() throws {
    try assertCellReferenceRoundTrip("AO41", row: 40, column: 40)
  }

  func testCellReferenceRoundTripMatrix0122() throws {
    try assertCellReferenceRoundTrip("BB48", row: 47, column: 53)
  }

  func testCellReferenceRoundTripMatrix0123() throws {
    try assertCellReferenceRoundTrip("BO55", row: 54, column: 66)
  }

  func testCellReferenceRoundTripMatrix0124() throws {
    try assertCellReferenceRoundTrip("CB62", row: 61, column: 79)
  }

  func testCellReferenceRoundTripMatrix0125() throws {
    try assertCellReferenceRoundTrip("M69", row: 68, column: 12)
  }

  func testCellReferenceRoundTripMatrix0126() throws {
    try assertCellReferenceRoundTrip("Z76", row: 75, column: 25)
  }

  func testCellReferenceRoundTripMatrix0127() throws {
    try assertCellReferenceRoundTrip("AM83", row: 82, column: 38)
  }

  func testCellReferenceRoundTripMatrix0128() throws {
    try assertCellReferenceRoundTrip("AZ90", row: 89, column: 51)
  }

  func testCellReferenceRoundTripMatrix0129() throws {
    try assertCellReferenceRoundTrip("BM97", row: 96, column: 64)
  }

  func testCellReferenceRoundTripMatrix0130() throws {
    try assertCellReferenceRoundTrip("BZ104", row: 103, column: 77)
  }

  func testCellReferenceRoundTripMatrix0131() throws {
    try assertCellReferenceRoundTrip("K111", row: 110, column: 10)
  }

  func testCellReferenceRoundTripMatrix0132() throws {
    try assertCellReferenceRoundTrip("X118", row: 117, column: 23)
  }

  func testCellReferenceRoundTripMatrix0133() throws {
    try assertCellReferenceRoundTrip("AK125", row: 124, column: 36)
  }

  func testCellReferenceRoundTripMatrix0134() throws {
    try assertCellReferenceRoundTrip("AX132", row: 131, column: 49)
  }

  func testCellReferenceRoundTripMatrix0135() throws {
    try assertCellReferenceRoundTrip("BK139", row: 138, column: 62)
  }

  func testCellReferenceRoundTripMatrix0136() throws {
    try assertCellReferenceRoundTrip("BX146", row: 145, column: 75)
  }

  func testCellReferenceRoundTripMatrix0137() throws {
    try assertCellReferenceRoundTrip("I153", row: 152, column: 8)
  }

  func testCellReferenceRoundTripMatrix0138() throws {
    try assertCellReferenceRoundTrip("V160", row: 159, column: 21)
  }

  func testCellReferenceRoundTripMatrix0139() throws {
    try assertCellReferenceRoundTrip("AI167", row: 166, column: 34)
  }

  func testCellReferenceRoundTripMatrix0140() throws {
    try assertCellReferenceRoundTrip("AV174", row: 173, column: 47)
  }

  func testCellReferenceRoundTripMatrix0141() throws {
    try assertCellReferenceRoundTrip("BI181", row: 180, column: 60)
  }

  func testCellReferenceRoundTripMatrix0142() throws {
    try assertCellReferenceRoundTrip("BV188", row: 187, column: 73)
  }

  func testCellReferenceRoundTripMatrix0143() throws {
    try assertCellReferenceRoundTrip("G195", row: 194, column: 6)
  }

  func testCellReferenceRoundTripMatrix0144() throws {
    try assertCellReferenceRoundTrip("T2", row: 1, column: 19)
  }

  func testCellReferenceRoundTripMatrix0145() throws {
    try assertCellReferenceRoundTrip("AG9", row: 8, column: 32)
  }

  func testCellReferenceRoundTripMatrix0146() throws {
    try assertCellReferenceRoundTrip("AT16", row: 15, column: 45)
  }

  func testCellReferenceRoundTripMatrix0147() throws {
    try assertCellReferenceRoundTrip("BG23", row: 22, column: 58)
  }

  func testCellReferenceRoundTripMatrix0148() throws {
    try assertCellReferenceRoundTrip("BT30", row: 29, column: 71)
  }

  func testCellReferenceRoundTripMatrix0149() throws {
    try assertCellReferenceRoundTrip("E37", row: 36, column: 4)
  }

  func testCellReferenceRoundTripMatrix0150() throws {
    try assertCellReferenceRoundTrip("R44", row: 43, column: 17)
  }

  func testCellReferenceRoundTripMatrix0151() throws {
    try assertCellReferenceRoundTrip("AE51", row: 50, column: 30)
  }

  func testCellReferenceRoundTripMatrix0152() throws {
    try assertCellReferenceRoundTrip("AR58", row: 57, column: 43)
  }

  func testCellReferenceRoundTripMatrix0153() throws {
    try assertCellReferenceRoundTrip("BE65", row: 64, column: 56)
  }

  func testCellReferenceRoundTripMatrix0154() throws {
    try assertCellReferenceRoundTrip("BR72", row: 71, column: 69)
  }

  func testCellReferenceRoundTripMatrix0155() throws {
    try assertCellReferenceRoundTrip("C79", row: 78, column: 2)
  }

  func testCellReferenceRoundTripMatrix0156() throws {
    try assertCellReferenceRoundTrip("P86", row: 85, column: 15)
  }

  func testCellReferenceRoundTripMatrix0157() throws {
    try assertCellReferenceRoundTrip("AC93", row: 92, column: 28)
  }

  func testCellReferenceRoundTripMatrix0158() throws {
    try assertCellReferenceRoundTrip("AP100", row: 99, column: 41)
  }

  func testCellReferenceRoundTripMatrix0159() throws {
    try assertCellReferenceRoundTrip("BC107", row: 106, column: 54)
  }

  func testCellReferenceRoundTripMatrix0160() throws {
    try assertCellReferenceRoundTrip("BP114", row: 113, column: 67)
  }

  func testCellReferenceRoundTripMatrix0161() throws {
    try assertCellReferenceRoundTrip("A121", row: 120, column: 0)
  }

  func testCellReferenceRoundTripMatrix0162() throws {
    try assertCellReferenceRoundTrip("N128", row: 127, column: 13)
  }

  func testCellReferenceRoundTripMatrix0163() throws {
    try assertCellReferenceRoundTrip("AA135", row: 134, column: 26)
  }

  func testCellReferenceRoundTripMatrix0164() throws {
    try assertCellReferenceRoundTrip("AN142", row: 141, column: 39)
  }

  func testCellReferenceRoundTripMatrix0165() throws {
    try assertCellReferenceRoundTrip("BA149", row: 148, column: 52)
  }

  func testCellReferenceRoundTripMatrix0166() throws {
    try assertCellReferenceRoundTrip("BN156", row: 155, column: 65)
  }

  func testCellReferenceRoundTripMatrix0167() throws {
    try assertCellReferenceRoundTrip("CA163", row: 162, column: 78)
  }

  func testCellReferenceRoundTripMatrix0168() throws {
    try assertCellReferenceRoundTrip("L170", row: 169, column: 11)
  }

  func testCellReferenceRoundTripMatrix0169() throws {
    try assertCellReferenceRoundTrip("Y177", row: 176, column: 24)
  }

  func testCellReferenceRoundTripMatrix0170() throws {
    try assertCellReferenceRoundTrip("AL184", row: 183, column: 37)
  }

  func testCellReferenceRoundTripMatrix0171() throws {
    try assertCellReferenceRoundTrip("AY191", row: 190, column: 50)
  }

  func testCellReferenceRoundTripMatrix0172() throws {
    try assertCellReferenceRoundTrip("BL198", row: 197, column: 63)
  }

  func testCellReferenceRoundTripMatrix0173() throws {
    try assertCellReferenceRoundTrip("BY5", row: 4, column: 76)
  }

  func testCellReferenceRoundTripMatrix0174() throws {
    try assertCellReferenceRoundTrip("J12", row: 11, column: 9)
  }

  func testCellReferenceRoundTripMatrix0175() throws {
    try assertCellReferenceRoundTrip("W19", row: 18, column: 22)
  }

  func testCellReferenceRoundTripMatrix0176() throws {
    try assertCellReferenceRoundTrip("AJ26", row: 25, column: 35)
  }

  func testCellReferenceRoundTripMatrix0177() throws {
    try assertCellReferenceRoundTrip("AW33", row: 32, column: 48)
  }

  func testCellReferenceRoundTripMatrix0178() throws {
    try assertCellReferenceRoundTrip("BJ40", row: 39, column: 61)
  }

  func testCellReferenceRoundTripMatrix0179() throws {
    try assertCellReferenceRoundTrip("BW47", row: 46, column: 74)
  }

  func testCellReferenceRoundTripMatrix0180() throws {
    try assertCellReferenceRoundTrip("H54", row: 53, column: 7)
  }

  func testCellReferenceRoundTripMatrix0181() throws {
    try assertCellReferenceRoundTrip("U61", row: 60, column: 20)
  }

  func testCellReferenceRoundTripMatrix0182() throws {
    try assertCellReferenceRoundTrip("AH68", row: 67, column: 33)
  }

  func testCellReferenceRoundTripMatrix0183() throws {
    try assertCellReferenceRoundTrip("AU75", row: 74, column: 46)
  }

  func testCellReferenceRoundTripMatrix0184() throws {
    try assertCellReferenceRoundTrip("BH82", row: 81, column: 59)
  }

  func testCellReferenceRoundTripMatrix0185() throws {
    try assertCellReferenceRoundTrip("BU89", row: 88, column: 72)
  }

  func testCellReferenceRoundTripMatrix0186() throws {
    try assertCellReferenceRoundTrip("F96", row: 95, column: 5)
  }

  func testCellReferenceRoundTripMatrix0187() throws {
    try assertCellReferenceRoundTrip("S103", row: 102, column: 18)
  }

  func testCellReferenceRoundTripMatrix0188() throws {
    try assertCellReferenceRoundTrip("AF110", row: 109, column: 31)
  }

  func testCellReferenceRoundTripMatrix0189() throws {
    try assertCellReferenceRoundTrip("AS117", row: 116, column: 44)
  }

  func testCellReferenceRoundTripMatrix0190() throws {
    try assertCellReferenceRoundTrip("BF124", row: 123, column: 57)
  }

  func testCellReferenceRoundTripMatrix0191() throws {
    try assertCellReferenceRoundTrip("BS131", row: 130, column: 70)
  }

  func testCellReferenceRoundTripMatrix0192() throws {
    try assertCellReferenceRoundTrip("D138", row: 137, column: 3)
  }

  func testCellReferenceRoundTripMatrix0193() throws {
    try assertCellReferenceRoundTrip("Q145", row: 144, column: 16)
  }

  func testCellReferenceRoundTripMatrix0194() throws {
    try assertCellReferenceRoundTrip("AD152", row: 151, column: 29)
  }

  func testCellReferenceRoundTripMatrix0195() throws {
    try assertCellReferenceRoundTrip("AQ159", row: 158, column: 42)
  }

  func testCellReferenceRoundTripMatrix0196() throws {
    try assertCellReferenceRoundTrip("BD166", row: 165, column: 55)
  }

  func testCellReferenceRoundTripMatrix0197() throws {
    try assertCellReferenceRoundTrip("BQ173", row: 172, column: 68)
  }

  func testCellReferenceRoundTripMatrix0198() throws {
    try assertCellReferenceRoundTrip("B180", row: 179, column: 1)
  }

  func testCellReferenceRoundTripMatrix0199() throws {
    try assertCellReferenceRoundTrip("O187", row: 186, column: 14)
  }

  func testCellReferenceRoundTripMatrix0200() throws {
    try assertCellReferenceRoundTrip("AB194", row: 193, column: 27)
  }

  func testCellReferenceRoundTripMatrix0201() throws {
    try assertCellReferenceRoundTrip("AO1", row: 0, column: 40)
  }

  func testCellReferenceRoundTripMatrix0202() throws {
    try assertCellReferenceRoundTrip("BB8", row: 7, column: 53)
  }

  func testCellReferenceRoundTripMatrix0203() throws {
    try assertCellReferenceRoundTrip("BO15", row: 14, column: 66)
  }

  func testCellReferenceRoundTripMatrix0204() throws {
    try assertCellReferenceRoundTrip("CB22", row: 21, column: 79)
  }

  func testCellReferenceRoundTripMatrix0205() throws {
    try assertCellReferenceRoundTrip("M29", row: 28, column: 12)
  }

  func testCellReferenceRoundTripMatrix0206() throws {
    try assertCellReferenceRoundTrip("Z36", row: 35, column: 25)
  }

  func testCellReferenceRoundTripMatrix0207() throws {
    try assertCellReferenceRoundTrip("AM43", row: 42, column: 38)
  }

  func testCellReferenceRoundTripMatrix0208() throws {
    try assertCellReferenceRoundTrip("AZ50", row: 49, column: 51)
  }

  func testCellReferenceRoundTripMatrix0209() throws {
    try assertCellReferenceRoundTrip("BM57", row: 56, column: 64)
  }

  func testCellReferenceRoundTripMatrix0210() throws {
    try assertCellReferenceRoundTrip("BZ64", row: 63, column: 77)
  }

  func testCellReferenceRoundTripMatrix0211() throws {
    try assertCellReferenceRoundTrip("K71", row: 70, column: 10)
  }

  func testCellReferenceRoundTripMatrix0212() throws {
    try assertCellReferenceRoundTrip("X78", row: 77, column: 23)
  }

  func testCellReferenceRoundTripMatrix0213() throws {
    try assertCellReferenceRoundTrip("AK85", row: 84, column: 36)
  }

  func testCellReferenceRoundTripMatrix0214() throws {
    try assertCellReferenceRoundTrip("AX92", row: 91, column: 49)
  }

  func testCellReferenceRoundTripMatrix0215() throws {
    try assertCellReferenceRoundTrip("BK99", row: 98, column: 62)
  }

  func testCellReferenceRoundTripMatrix0216() throws {
    try assertCellReferenceRoundTrip("BX106", row: 105, column: 75)
  }

  func testCellReferenceRoundTripMatrix0217() throws {
    try assertCellReferenceRoundTrip("I113", row: 112, column: 8)
  }

  func testCellReferenceRoundTripMatrix0218() throws {
    try assertCellReferenceRoundTrip("V120", row: 119, column: 21)
  }

  func testCellReferenceRoundTripMatrix0219() throws {
    try assertCellReferenceRoundTrip("AI127", row: 126, column: 34)
  }

  func testCellReferenceRoundTripMatrix0220() throws {
    try assertCellReferenceRoundTrip("AV134", row: 133, column: 47)
  }

  func testCellReferenceRoundTripMatrix0221() throws {
    try assertCellReferenceRoundTrip("BI141", row: 140, column: 60)
  }

  func testCellReferenceRoundTripMatrix0222() throws {
    try assertCellReferenceRoundTrip("BV148", row: 147, column: 73)
  }

  func testCellReferenceRoundTripMatrix0223() throws {
    try assertCellReferenceRoundTrip("G155", row: 154, column: 6)
  }

  func testCellReferenceRoundTripMatrix0224() throws {
    try assertCellReferenceRoundTrip("T162", row: 161, column: 19)
  }

  func testCellReferenceRoundTripMatrix0225() throws {
    try assertCellReferenceRoundTrip("AG169", row: 168, column: 32)
  }

  func testCellReferenceRoundTripMatrix0226() throws {
    try assertCellReferenceRoundTrip("AT176", row: 175, column: 45)
  }

  func testCellReferenceRoundTripMatrix0227() throws {
    try assertCellReferenceRoundTrip("BG183", row: 182, column: 58)
  }

  func testCellReferenceRoundTripMatrix0228() throws {
    try assertCellReferenceRoundTrip("BT190", row: 189, column: 71)
  }

  func testCellReferenceRoundTripMatrix0229() throws {
    try assertCellReferenceRoundTrip("E197", row: 196, column: 4)
  }

  func testCellReferenceRoundTripMatrix0230() throws {
    try assertCellReferenceRoundTrip("R4", row: 3, column: 17)
  }

  func testCellReferenceRoundTripMatrix0231() throws {
    try assertCellReferenceRoundTrip("AE11", row: 10, column: 30)
  }

  func testCellReferenceRoundTripMatrix0232() throws {
    try assertCellReferenceRoundTrip("AR18", row: 17, column: 43)
  }

  func testCellReferenceRoundTripMatrix0233() throws {
    try assertCellReferenceRoundTrip("BE25", row: 24, column: 56)
  }

  func testCellReferenceRoundTripMatrix0234() throws {
    try assertCellReferenceRoundTrip("BR32", row: 31, column: 69)
  }

  func testCellReferenceRoundTripMatrix0235() throws {
    try assertCellReferenceRoundTrip("C39", row: 38, column: 2)
  }

  func testCellReferenceRoundTripMatrix0236() throws {
    try assertCellReferenceRoundTrip("P46", row: 45, column: 15)
  }

  func testCellReferenceRoundTripMatrix0237() throws {
    try assertCellReferenceRoundTrip("AC53", row: 52, column: 28)
  }

  func testCellReferenceRoundTripMatrix0238() throws {
    try assertCellReferenceRoundTrip("AP60", row: 59, column: 41)
  }

  func testCellReferenceRoundTripMatrix0239() throws {
    try assertCellReferenceRoundTrip("BC67", row: 66, column: 54)
  }

  func testCellReferenceRoundTripMatrix0240() throws {
    try assertCellReferenceRoundTrip("BP74", row: 73, column: 67)
  }

  func testCellReferenceRoundTripMatrix0241() throws {
    try assertCellReferenceRoundTrip("A81", row: 80, column: 0)
  }

  func testCellReferenceRoundTripMatrix0242() throws {
    try assertCellReferenceRoundTrip("N88", row: 87, column: 13)
  }

  func testCellReferenceRoundTripMatrix0243() throws {
    try assertCellReferenceRoundTrip("AA95", row: 94, column: 26)
  }

  func testCellReferenceRoundTripMatrix0244() throws {
    try assertCellReferenceRoundTrip("AN102", row: 101, column: 39)
  }

  func testCellReferenceRoundTripMatrix0245() throws {
    try assertCellReferenceRoundTrip("BA109", row: 108, column: 52)
  }

  func testCellReferenceRoundTripMatrix0246() throws {
    try assertCellReferenceRoundTrip("BN116", row: 115, column: 65)
  }

  func testCellReferenceRoundTripMatrix0247() throws {
    try assertCellReferenceRoundTrip("CA123", row: 122, column: 78)
  }

  func testCellReferenceRoundTripMatrix0248() throws {
    try assertCellReferenceRoundTrip("L130", row: 129, column: 11)
  }

  func testCellReferenceRoundTripMatrix0249() throws {
    try assertCellReferenceRoundTrip("Y137", row: 136, column: 24)
  }

  func testCellReferenceRoundTripMatrix0250() throws {
    try assertCellReferenceRoundTrip("AL144", row: 143, column: 37)
  }

  func testCellReferenceRoundTripMatrix0251() throws {
    try assertCellReferenceRoundTrip("AY151", row: 150, column: 50)
  }

  func testCellReferenceRoundTripMatrix0252() throws {
    try assertCellReferenceRoundTrip("BL158", row: 157, column: 63)
  }

  func testCellReferenceRoundTripMatrix0253() throws {
    try assertCellReferenceRoundTrip("BY165", row: 164, column: 76)
  }

  func testCellReferenceRoundTripMatrix0254() throws {
    try assertCellReferenceRoundTrip("J172", row: 171, column: 9)
  }

  func testCellReferenceRoundTripMatrix0255() throws {
    try assertCellReferenceRoundTrip("W179", row: 178, column: 22)
  }

  func testCellReferenceRoundTripMatrix0256() throws {
    try assertCellReferenceRoundTrip("AJ186", row: 185, column: 35)
  }

  func testCellReferenceRoundTripMatrix0257() throws {
    try assertCellReferenceRoundTrip("AW193", row: 192, column: 48)
  }

  func testCellReferenceRoundTripMatrix0258() throws {
    try assertCellReferenceRoundTrip("BJ200", row: 199, column: 61)
  }

  func testCellReferenceRoundTripMatrix0259() throws {
    try assertCellReferenceRoundTrip("BW7", row: 6, column: 74)
  }

  func testCellReferenceRoundTripMatrix0260() throws {
    try assertCellReferenceRoundTrip("H14", row: 13, column: 7)
  }

  func testCellReferenceRoundTripMatrix0261() throws {
    try assertCellReferenceRoundTrip("U21", row: 20, column: 20)
  }

  func testCellReferenceRoundTripMatrix0262() throws {
    try assertCellReferenceRoundTrip("AH28", row: 27, column: 33)
  }

  func testCellReferenceRoundTripMatrix0263() throws {
    try assertCellReferenceRoundTrip("AU35", row: 34, column: 46)
  }

  func testCellReferenceRoundTripMatrix0264() throws {
    try assertCellReferenceRoundTrip("BH42", row: 41, column: 59)
  }

  func testCellReferenceRoundTripMatrix0265() throws {
    try assertCellReferenceRoundTrip("BU49", row: 48, column: 72)
  }

  func testCellReferenceRoundTripMatrix0266() throws {
    try assertCellReferenceRoundTrip("F56", row: 55, column: 5)
  }

  func testCellReferenceRoundTripMatrix0267() throws {
    try assertCellReferenceRoundTrip("S63", row: 62, column: 18)
  }

  func testCellReferenceRoundTripMatrix0268() throws {
    try assertCellReferenceRoundTrip("AF70", row: 69, column: 31)
  }

  func testCellReferenceRoundTripMatrix0269() throws {
    try assertCellReferenceRoundTrip("AS77", row: 76, column: 44)
  }

  func testCellReferenceRoundTripMatrix0270() throws {
    try assertCellReferenceRoundTrip("BF84", row: 83, column: 57)
  }

  func testCellReferenceRoundTripMatrix0271() throws {
    try assertCellReferenceRoundTrip("BS91", row: 90, column: 70)
  }

  func testCellReferenceRoundTripMatrix0272() throws {
    try assertCellReferenceRoundTrip("D98", row: 97, column: 3)
  }

  func testCellReferenceRoundTripMatrix0273() throws {
    try assertCellReferenceRoundTrip("Q105", row: 104, column: 16)
  }

  func testCellReferenceRoundTripMatrix0274() throws {
    try assertCellReferenceRoundTrip("AD112", row: 111, column: 29)
  }

  func testCellReferenceRoundTripMatrix0275() throws {
    try assertCellReferenceRoundTrip("AQ119", row: 118, column: 42)
  }

  func testCellReferenceRoundTripMatrix0276() throws {
    try assertCellReferenceRoundTrip("BD126", row: 125, column: 55)
  }

  func testCellReferenceRoundTripMatrix0277() throws {
    try assertCellReferenceRoundTrip("BQ133", row: 132, column: 68)
  }

  func testCellReferenceRoundTripMatrix0278() throws {
    try assertCellReferenceRoundTrip("B140", row: 139, column: 1)
  }

  func testCellReferenceRoundTripMatrix0279() throws {
    try assertCellReferenceRoundTrip("O147", row: 146, column: 14)
  }

  func testCellReferenceRoundTripMatrix0280() throws {
    try assertCellReferenceRoundTrip("AB154", row: 153, column: 27)
  }

  func testCellReferenceRoundTripMatrix0281() throws {
    try assertCellReferenceRoundTrip("AO161", row: 160, column: 40)
  }

  func testCellReferenceRoundTripMatrix0282() throws {
    try assertCellReferenceRoundTrip("BB168", row: 167, column: 53)
  }

  func testCellReferenceRoundTripMatrix0283() throws {
    try assertCellReferenceRoundTrip("BO175", row: 174, column: 66)
  }

  func testCellReferenceRoundTripMatrix0284() throws {
    try assertCellReferenceRoundTrip("CB182", row: 181, column: 79)
  }

  func testCellReferenceRoundTripMatrix0285() throws {
    try assertCellReferenceRoundTrip("M189", row: 188, column: 12)
  }

  func testCellReferenceRoundTripMatrix0286() throws {
    try assertCellReferenceRoundTrip("Z196", row: 195, column: 25)
  }

  func testCellReferenceRoundTripMatrix0287() throws {
    try assertCellReferenceRoundTrip("AM3", row: 2, column: 38)
  }

  func testCellReferenceRoundTripMatrix0288() throws {
    try assertCellReferenceRoundTrip("AZ10", row: 9, column: 51)
  }

  func testCellReferenceRoundTripMatrix0289() throws {
    try assertCellReferenceRoundTrip("BM17", row: 16, column: 64)
  }

  func testCellReferenceRoundTripMatrix0290() throws {
    try assertCellReferenceRoundTrip("BZ24", row: 23, column: 77)
  }

  func testCellReferenceRoundTripMatrix0291() throws {
    try assertCellReferenceRoundTrip("K31", row: 30, column: 10)
  }

  func testCellReferenceRoundTripMatrix0292() throws {
    try assertCellReferenceRoundTrip("X38", row: 37, column: 23)
  }

  func testCellReferenceRoundTripMatrix0293() throws {
    try assertCellReferenceRoundTrip("AK45", row: 44, column: 36)
  }

  func testCellReferenceRoundTripMatrix0294() throws {
    try assertCellReferenceRoundTrip("AX52", row: 51, column: 49)
  }

  func testCellReferenceRoundTripMatrix0295() throws {
    try assertCellReferenceRoundTrip("BK59", row: 58, column: 62)
  }

  func testCellReferenceRoundTripMatrix0296() throws {
    try assertCellReferenceRoundTrip("BX66", row: 65, column: 75)
  }

  func testCellReferenceRoundTripMatrix0297() throws {
    try assertCellReferenceRoundTrip("I73", row: 72, column: 8)
  }

  func testCellReferenceRoundTripMatrix0298() throws {
    try assertCellReferenceRoundTrip("V80", row: 79, column: 21)
  }

  func testCellReferenceRoundTripMatrix0299() throws {
    try assertCellReferenceRoundTrip("AI87", row: 86, column: 34)
  }

  func testCellReferenceRoundTripMatrix0300() throws {
    try assertCellReferenceRoundTrip("AV94", row: 93, column: 47)
  }

  func testCellReferenceRoundTripMatrix0301() throws {
    try assertCellReferenceRoundTrip("BI101", row: 100, column: 60)
  }

  func testCellReferenceRoundTripMatrix0302() throws {
    try assertCellReferenceRoundTrip("BV108", row: 107, column: 73)
  }

  func testCellReferenceRoundTripMatrix0303() throws {
    try assertCellReferenceRoundTrip("G115", row: 114, column: 6)
  }

  func testCellReferenceRoundTripMatrix0304() throws {
    try assertCellReferenceRoundTrip("T122", row: 121, column: 19)
  }

  func testCellReferenceRoundTripMatrix0305() throws {
    try assertCellReferenceRoundTrip("AG129", row: 128, column: 32)
  }

  func testCellReferenceRoundTripMatrix0306() throws {
    try assertCellReferenceRoundTrip("AT136", row: 135, column: 45)
  }

  func testCellReferenceRoundTripMatrix0307() throws {
    try assertCellReferenceRoundTrip("BG143", row: 142, column: 58)
  }

  func testCellReferenceRoundTripMatrix0308() throws {
    try assertCellReferenceRoundTrip("BT150", row: 149, column: 71)
  }

  func testCellReferenceRoundTripMatrix0309() throws {
    try assertCellReferenceRoundTrip("E157", row: 156, column: 4)
  }

  func testCellReferenceRoundTripMatrix0310() throws {
    try assertCellReferenceRoundTrip("R164", row: 163, column: 17)
  }

  func testCellReferenceRoundTripMatrix0311() throws {
    try assertCellReferenceRoundTrip("AE171", row: 170, column: 30)
  }

  func testCellReferenceRoundTripMatrix0312() throws {
    try assertCellReferenceRoundTrip("AR178", row: 177, column: 43)
  }

  func testCellReferenceRoundTripMatrix0313() throws {
    try assertCellReferenceRoundTrip("BE185", row: 184, column: 56)
  }

  func testCellReferenceRoundTripMatrix0314() throws {
    try assertCellReferenceRoundTrip("BR192", row: 191, column: 69)
  }

  func testCellReferenceRoundTripMatrix0315() throws {
    try assertCellReferenceRoundTrip("C199", row: 198, column: 2)
  }

  func testCellReferenceRoundTripMatrix0316() throws {
    try assertCellReferenceRoundTrip("P6", row: 5, column: 15)
  }

  func testCellReferenceRoundTripMatrix0317() throws {
    try assertCellReferenceRoundTrip("AC13", row: 12, column: 28)
  }

  func testCellReferenceRoundTripMatrix0318() throws {
    try assertCellReferenceRoundTrip("AP20", row: 19, column: 41)
  }

  func testCellReferenceRoundTripMatrix0319() throws {
    try assertCellReferenceRoundTrip("BC27", row: 26, column: 54)
  }

  func testCellReferenceRoundTripMatrix0320() throws {
    try assertCellReferenceRoundTrip("BP34", row: 33, column: 67)
  }

  func testCellReferenceRoundTripMatrix0321() throws {
    try assertCellReferenceRoundTrip("A41", row: 40, column: 0)
  }

  func testCellReferenceRoundTripMatrix0322() throws {
    try assertCellReferenceRoundTrip("N48", row: 47, column: 13)
  }

  func testCellReferenceRoundTripMatrix0323() throws {
    try assertCellReferenceRoundTrip("AA55", row: 54, column: 26)
  }

  func testCellReferenceRoundTripMatrix0324() throws {
    try assertCellReferenceRoundTrip("AN62", row: 61, column: 39)
  }

  func testCellReferenceRoundTripMatrix0325() throws {
    try assertCellReferenceRoundTrip("BA69", row: 68, column: 52)
  }

  func testCellReferenceRoundTripMatrix0326() throws {
    try assertCellReferenceRoundTrip("BN76", row: 75, column: 65)
  }

  func testCellReferenceRoundTripMatrix0327() throws {
    try assertCellReferenceRoundTrip("CA83", row: 82, column: 78)
  }

  func testCellReferenceRoundTripMatrix0328() throws {
    try assertCellReferenceRoundTrip("L90", row: 89, column: 11)
  }

  func testCellReferenceRoundTripMatrix0329() throws {
    try assertCellReferenceRoundTrip("Y97", row: 96, column: 24)
  }

  func testCellReferenceRoundTripMatrix0330() throws {
    try assertCellReferenceRoundTrip("AL104", row: 103, column: 37)
  }

  func testCellReferenceRoundTripMatrix0331() throws {
    try assertCellReferenceRoundTrip("AY111", row: 110, column: 50)
  }

  func testCellReferenceRoundTripMatrix0332() throws {
    try assertCellReferenceRoundTrip("BL118", row: 117, column: 63)
  }

  func testCellReferenceRoundTripMatrix0333() throws {
    try assertCellReferenceRoundTrip("BY125", row: 124, column: 76)
  }

  func testCellReferenceRoundTripMatrix0334() throws {
    try assertCellReferenceRoundTrip("J132", row: 131, column: 9)
  }

  func testCellReferenceRoundTripMatrix0335() throws {
    try assertCellReferenceRoundTrip("W139", row: 138, column: 22)
  }

  func testCellReferenceRoundTripMatrix0336() throws {
    try assertCellReferenceRoundTrip("AJ146", row: 145, column: 35)
  }

  func testCellReferenceRoundTripMatrix0337() throws {
    try assertCellReferenceRoundTrip("AW153", row: 152, column: 48)
  }

  func testCellReferenceRoundTripMatrix0338() throws {
    try assertCellReferenceRoundTrip("BJ160", row: 159, column: 61)
  }

  func testCellReferenceRoundTripMatrix0339() throws {
    try assertCellReferenceRoundTrip("BW167", row: 166, column: 74)
  }

  func testCellReferenceRoundTripMatrix0340() throws {
    try assertCellReferenceRoundTrip("H174", row: 173, column: 7)
  }

  func testCellReferenceRoundTripMatrix0341() throws {
    try assertCellReferenceRoundTrip("U181", row: 180, column: 20)
  }

  func testCellReferenceRoundTripMatrix0342() throws {
    try assertCellReferenceRoundTrip("AH188", row: 187, column: 33)
  }

  func testCellReferenceRoundTripMatrix0343() throws {
    try assertCellReferenceRoundTrip("AU195", row: 194, column: 46)
  }

  func testCellReferenceRoundTripMatrix0344() throws {
    try assertCellReferenceRoundTrip("BH2", row: 1, column: 59)
  }

  func testCellReferenceRoundTripMatrix0345() throws {
    try assertCellReferenceRoundTrip("BU9", row: 8, column: 72)
  }

  func testCellReferenceRoundTripMatrix0346() throws {
    try assertCellReferenceRoundTrip("F16", row: 15, column: 5)
  }

  func testCellReferenceRoundTripMatrix0347() throws {
    try assertCellReferenceRoundTrip("S23", row: 22, column: 18)
  }

  func testCellReferenceRoundTripMatrix0348() throws {
    try assertCellReferenceRoundTrip("AF30", row: 29, column: 31)
  }

  func testCellReferenceRoundTripMatrix0349() throws {
    try assertCellReferenceRoundTrip("AS37", row: 36, column: 44)
  }

  func testCellReferenceRoundTripMatrix0350() throws {
    try assertCellReferenceRoundTrip("BF44", row: 43, column: 57)
  }

  func testCellReferenceRoundTripMatrix0351() throws {
    try assertCellReferenceRoundTrip("BS51", row: 50, column: 70)
  }

  func testCellReferenceRoundTripMatrix0352() throws {
    try assertCellReferenceRoundTrip("D58", row: 57, column: 3)
  }

  func testCellReferenceRoundTripMatrix0353() throws {
    try assertCellReferenceRoundTrip("Q65", row: 64, column: 16)
  }

  func testCellReferenceRoundTripMatrix0354() throws {
    try assertCellReferenceRoundTrip("AD72", row: 71, column: 29)
  }

  func testCellReferenceRoundTripMatrix0355() throws {
    try assertCellReferenceRoundTrip("AQ79", row: 78, column: 42)
  }

  func testCellReferenceRoundTripMatrix0356() throws {
    try assertCellReferenceRoundTrip("BD86", row: 85, column: 55)
  }

  func testCellReferenceRoundTripMatrix0357() throws {
    try assertCellReferenceRoundTrip("BQ93", row: 92, column: 68)
  }

  func testCellReferenceRoundTripMatrix0358() throws {
    try assertCellReferenceRoundTrip("B100", row: 99, column: 1)
  }

  func testCellReferenceRoundTripMatrix0359() throws {
    try assertCellReferenceRoundTrip("O107", row: 106, column: 14)
  }

  func testCellReferenceRoundTripMatrix0360() throws {
    try assertCellReferenceRoundTrip("AB114", row: 113, column: 27)
  }

  func testCellReferenceRoundTripMatrix0361() throws {
    try assertCellReferenceRoundTrip("AO121", row: 120, column: 40)
  }

  func testCellReferenceRoundTripMatrix0362() throws {
    try assertCellReferenceRoundTrip("BB128", row: 127, column: 53)
  }

  func testCellReferenceRoundTripMatrix0363() throws {
    try assertCellReferenceRoundTrip("BO135", row: 134, column: 66)
  }

  func testCellReferenceRoundTripMatrix0364() throws {
    try assertCellReferenceRoundTrip("CB142", row: 141, column: 79)
  }

  func testCellReferenceRoundTripMatrix0365() throws {
    try assertCellReferenceRoundTrip("M149", row: 148, column: 12)
  }

  func testCellReferenceRoundTripMatrix0366() throws {
    try assertCellReferenceRoundTrip("Z156", row: 155, column: 25)
  }

  func testCellReferenceRoundTripMatrix0367() throws {
    try assertCellReferenceRoundTrip("AM163", row: 162, column: 38)
  }

  func testCellReferenceRoundTripMatrix0368() throws {
    try assertCellReferenceRoundTrip("AZ170", row: 169, column: 51)
  }

  func testCellReferenceRoundTripMatrix0369() throws {
    try assertCellReferenceRoundTrip("BM177", row: 176, column: 64)
  }

  func testCellReferenceRoundTripMatrix0370() throws {
    try assertCellReferenceRoundTrip("BZ184", row: 183, column: 77)
  }

  func testCellReferenceRoundTripMatrix0371() throws {
    try assertCellReferenceRoundTrip("K191", row: 190, column: 10)
  }

  func testCellReferenceRoundTripMatrix0372() throws {
    try assertCellReferenceRoundTrip("X198", row: 197, column: 23)
  }

  func testCellReferenceRoundTripMatrix0373() throws {
    try assertCellReferenceRoundTrip("AK5", row: 4, column: 36)
  }

  func testCellReferenceRoundTripMatrix0374() throws {
    try assertCellReferenceRoundTrip("AX12", row: 11, column: 49)
  }

  func testCellReferenceRoundTripMatrix0375() throws {
    try assertCellReferenceRoundTrip("BK19", row: 18, column: 62)
  }

  func testCellReferenceRoundTripMatrix0376() throws {
    try assertCellReferenceRoundTrip("BX26", row: 25, column: 75)
  }

  func testCellReferenceRoundTripMatrix0377() throws {
    try assertCellReferenceRoundTrip("I33", row: 32, column: 8)
  }

  func testCellReferenceRoundTripMatrix0378() throws {
    try assertCellReferenceRoundTrip("V40", row: 39, column: 21)
  }

  func testCellReferenceRoundTripMatrix0379() throws {
    try assertCellReferenceRoundTrip("AI47", row: 46, column: 34)
  }

  func testCellReferenceRoundTripMatrix0380() throws {
    try assertCellReferenceRoundTrip("AV54", row: 53, column: 47)
  }

  func testCellReferenceRoundTripMatrix0381() throws {
    try assertCellReferenceRoundTrip("BI61", row: 60, column: 60)
  }

  func testCellReferenceRoundTripMatrix0382() throws {
    try assertCellReferenceRoundTrip("BV68", row: 67, column: 73)
  }

  func testCellReferenceRoundTripMatrix0383() throws {
    try assertCellReferenceRoundTrip("G75", row: 74, column: 6)
  }

  func testCellReferenceRoundTripMatrix0384() throws {
    try assertCellReferenceRoundTrip("T82", row: 81, column: 19)
  }

  func testCellReferenceRoundTripMatrix0385() throws {
    try assertCellReferenceRoundTrip("AG89", row: 88, column: 32)
  }

  func testCellReferenceRoundTripMatrix0386() throws {
    try assertCellReferenceRoundTrip("AT96", row: 95, column: 45)
  }

  func testCellReferenceRoundTripMatrix0387() throws {
    try assertCellReferenceRoundTrip("BG103", row: 102, column: 58)
  }

  func testCellReferenceRoundTripMatrix0388() throws {
    try assertCellReferenceRoundTrip("BT110", row: 109, column: 71)
  }

  func testCellReferenceRoundTripMatrix0389() throws {
    try assertCellReferenceRoundTrip("E117", row: 116, column: 4)
  }

  func testCellReferenceRoundTripMatrix0390() throws {
    try assertCellReferenceRoundTrip("R124", row: 123, column: 17)
  }

  func testCellReferenceRoundTripMatrix0391() throws {
    try assertCellReferenceRoundTrip("AE131", row: 130, column: 30)
  }

  func testCellReferenceRoundTripMatrix0392() throws {
    try assertCellReferenceRoundTrip("AR138", row: 137, column: 43)
  }

  func testCellReferenceRoundTripMatrix0393() throws {
    try assertCellReferenceRoundTrip("BE145", row: 144, column: 56)
  }

  func testCellReferenceRoundTripMatrix0394() throws {
    try assertCellReferenceRoundTrip("BR152", row: 151, column: 69)
  }

  func testCellReferenceRoundTripMatrix0395() throws {
    try assertCellReferenceRoundTrip("C159", row: 158, column: 2)
  }

  func testCellReferenceRoundTripMatrix0396() throws {
    try assertCellReferenceRoundTrip("P166", row: 165, column: 15)
  }

  func testCellReferenceRoundTripMatrix0397() throws {
    try assertCellReferenceRoundTrip("AC173", row: 172, column: 28)
  }

  func testCellReferenceRoundTripMatrix0398() throws {
    try assertCellReferenceRoundTrip("AP180", row: 179, column: 41)
  }

  func testCellReferenceRoundTripMatrix0399() throws {
    try assertCellReferenceRoundTrip("BC187", row: 186, column: 54)
  }

  func testCellReferenceRoundTripMatrix0400() throws {
    try assertCellReferenceRoundTrip("BP194", row: 193, column: 67)
  }

}
