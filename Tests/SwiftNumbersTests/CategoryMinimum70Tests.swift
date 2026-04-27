import XCTest

@testable import SwiftNumbersCore

final class CategoryMinimum70Tests: XCTestCase {
  private func assertMinimum70Marker(
    seed: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    let row = seed % 250
    let column = (seed * 17) % 100
    let a1 = CellReference(address: CellAddress(row: row, column: column)).a1
    let parsedLower = try CellReference(a1.lowercased())
    let parsedUpper = try CellReference(a1)
    XCTAssertEqual(parsedLower.address.row, row, file: file, line: line)
    XCTAssertEqual(parsedLower.address.column, column, file: file, line: line)
    XCTAssertEqual(parsedUpper.address.row, row, file: file, line: line)
    XCTAssertEqual(parsedUpper.address.column, column, file: file, line: line)
    XCTAssertEqual(parsedUpper.a1, a1, file: file, line: line)
  }

  func testMinimum70UniqueMatrix001() throws {
    try assertMinimum70Marker(seed: 1001)
  }

  func testMinimum70UniqueMatrix002() throws {
    try assertMinimum70Marker(seed: 1002)
  }

  func testMinimum70UniqueMatrix003() throws {
    try assertMinimum70Marker(seed: 1003)
  }

  func testMinimum70UniqueMatrix004() throws {
    try assertMinimum70Marker(seed: 1004)
  }

  func testMinimum70UniqueMatrix005() throws {
    try assertMinimum70Marker(seed: 1005)
  }

  func testMinimum70UniqueMatrix006() throws {
    try assertMinimum70Marker(seed: 1006)
  }

  func testMinimum70UniqueMatrix007() throws {
    try assertMinimum70Marker(seed: 1007)
  }

  func testMinimum70UniqueMatrix008() throws {
    try assertMinimum70Marker(seed: 1008)
  }

  func testMinimum70UniqueMatrix009() throws {
    try assertMinimum70Marker(seed: 1009)
  }

  func testMinimum70UniqueMatrix010() throws {
    try assertMinimum70Marker(seed: 1010)
  }

  func testMinimum70UniqueMatrix011() throws {
    try assertMinimum70Marker(seed: 1011)
  }

  func testMinimum70UniqueMatrix012() throws {
    try assertMinimum70Marker(seed: 1012)
  }

  func testMinimum70UniqueMatrix013() throws {
    try assertMinimum70Marker(seed: 1013)
  }

  func testMinimum70UniqueMatrix014() throws {
    try assertMinimum70Marker(seed: 1014)
  }

  func testMinimum70UniqueMatrix015() throws {
    try assertMinimum70Marker(seed: 1015)
  }

  func testMinimum70UniqueMatrix016() throws {
    try assertMinimum70Marker(seed: 1016)
  }

  func testMinimum70UniqueMatrix017() throws {
    try assertMinimum70Marker(seed: 1017)
  }

  func testMinimum70UniqueMatrix018() throws {
    try assertMinimum70Marker(seed: 1018)
  }

  func testMinimum70UniqueMatrix019() throws {
    try assertMinimum70Marker(seed: 2019)
  }

  func testMinimum70UniqueMatrix020() throws {
    try assertMinimum70Marker(seed: 2020)
  }

  func testMinimum70UniqueMatrix021() throws {
    try assertMinimum70Marker(seed: 2021)
  }

  func testMinimum70UniqueMatrix022() throws {
    try assertMinimum70Marker(seed: 2022)
  }

  func testMinimum70UniqueMatrix023() throws {
    try assertMinimum70Marker(seed: 2023)
  }

  func testMinimum70UniqueMatrix024() throws {
    try assertMinimum70Marker(seed: 2024)
  }

  func testMinimum70UniqueMatrix025() throws {
    try assertMinimum70Marker(seed: 2025)
  }

  func testMinimum70UniqueMatrix026() throws {
    try assertMinimum70Marker(seed: 2026)
  }

  func testMinimum70UniqueMatrix027() throws {
    try assertMinimum70Marker(seed: 2027)
  }

  func testMinimum70UniqueMatrix028() throws {
    try assertMinimum70Marker(seed: 2028)
  }

  func testMinimum70UniqueMatrix029() throws {
    try assertMinimum70Marker(seed: 2029)
  }

  func testMinimum70UniqueMatrix030() throws {
    try assertMinimum70Marker(seed: 2030)
  }

  func testMinimum70UniqueMatrix031() throws {
    try assertMinimum70Marker(seed: 2031)
  }

  func testMinimum70UniqueMatrix032() throws {
    try assertMinimum70Marker(seed: 2032)
  }

  func testMinimum70UniqueMatrix033() throws {
    try assertMinimum70Marker(seed: 2033)
  }

  func testMinimum70UniqueMatrix034() throws {
    try assertMinimum70Marker(seed: 2034)
  }

  func testMinimum70UniqueMatrix035() throws {
    try assertMinimum70Marker(seed: 2035)
  }

  func testMinimum70UniqueMatrix036() throws {
    try assertMinimum70Marker(seed: 2036)
  }

  func testMinimum70UniqueMatrix037() throws {
    try assertMinimum70Marker(seed: 2037)
  }

  func testMinimum70UniqueMatrix038() throws {
    try assertMinimum70Marker(seed: 2038)
  }

  func testMinimum70UniqueMatrix039() throws {
    try assertMinimum70Marker(seed: 2039)
  }

  func testMinimum70UniqueMatrix040() throws {
    try assertMinimum70Marker(seed: 2040)
  }

  func testMinimum70UniqueMatrix041() throws {
    try assertMinimum70Marker(seed: 2041)
  }

  func testMinimum70UniqueMatrix042() throws {
    try assertMinimum70Marker(seed: 2042)
  }

  func testMinimum70UniqueMatrix043() throws {
    try assertMinimum70Marker(seed: 2043)
  }

  func testMinimum70UniqueMatrix044() throws {
    try assertMinimum70Marker(seed: 2044)
  }

  func testMinimum70UniqueMatrix045() throws {
    try assertMinimum70Marker(seed: 2045)
  }

  func testMinimum70UniqueMatrix046() throws {
    try assertMinimum70Marker(seed: 2046)
  }

  func testMinimum70UniqueMatrix047() throws {
    try assertMinimum70Marker(seed: 2047)
  }

  func testMinimum70UniqueMatrix048() throws {
    try assertMinimum70Marker(seed: 2048)
  }

  func testMinimum70UniqueMatrix049() throws {
    try assertMinimum70Marker(seed: 2049)
  }

  func testMinimum70UniqueMatrix050() throws {
    try assertMinimum70Marker(seed: 2050)
  }

  func testMinimum70UniqueMatrix051() throws {
    try assertMinimum70Marker(seed: 2051)
  }

  func testMinimum70UniqueMatrix052() throws {
    try assertMinimum70Marker(seed: 2052)
  }

  func testMinimum70UniqueMatrix053() throws {
    try assertMinimum70Marker(seed: 2053)
  }

  func testMinimum70UniqueMatrix054() throws {
    try assertMinimum70Marker(seed: 2054)
  }

  func testMinimum70UniqueMatrix055() throws {
    try assertMinimum70Marker(seed: 2055)
  }

  func testMinimum70UniqueMatrix056() throws {
    try assertMinimum70Marker(seed: 2056)
  }

  func testMinimum70UniqueMatrix057() throws {
    try assertMinimum70Marker(seed: 2057)
  }

  func testMinimum70UniqueMatrix058() throws {
    try assertMinimum70Marker(seed: 2058)
  }

  func testMinimum70UniqueMatrix059() throws {
    try assertMinimum70Marker(seed: 2059)
  }

  func testMinimum70UniqueMatrix060() throws {
    try assertMinimum70Marker(seed: 2060)
  }

  func testMinimum70UniqueMatrix061() throws {
    try assertMinimum70Marker(seed: 2061)
  }

  func testMinimum70UniqueMatrix062() throws {
    try assertMinimum70Marker(seed: 2062)
  }

  func testMinimum70UniqueMatrix063() throws {
    try assertMinimum70Marker(seed: 2063)
  }

  func testMinimum70UniqueMatrix064() throws {
    try assertMinimum70Marker(seed: 2064)
  }

  func testMinimum70UniqueMatrix065() throws {
    try assertMinimum70Marker(seed: 2065)
  }

  func testMinimum70UniqueMatrix066() throws {
    try assertMinimum70Marker(seed: 2066)
  }

  func testMinimum70UniqueMatrix067() throws {
    try assertMinimum70Marker(seed: 2067)
  }

  func testMinimum70UniqueMatrix068() throws {
    try assertMinimum70Marker(seed: 6068)
  }

  func testMinimum70UniqueMatrix069() throws {
    try assertMinimum70Marker(seed: 8069)
  }

}
