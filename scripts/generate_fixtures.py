#!/usr/bin/env python3
import json
import shutil
import struct
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "Fixtures"


def make_blob(records):
    payload = bytearray(b"SNIWA1\x00")
    payload.extend(struct.pack("<I", len(records)))
    for object_id, type_id, raw in records:
        payload.extend(struct.pack("<Q", object_id))
        payload.extend(struct.pack("<I", type_id))
        payload.extend(struct.pack("<I", len(raw)))
        payload.extend(raw)
    return bytes(payload)


def write_fixture(name, metadata, blobs):
    fixture = FIXTURES / f"{name}.numbers"
    if fixture.exists():
        shutil.rmtree(fixture)
    (fixture / "Metadata").mkdir(parents=True)

    with open(fixture / "Metadata" / "DocumentMetadata.json", "w", encoding="utf-8") as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
        f.write("\n")

    with zipfile.ZipFile(fixture / "Index.zip", "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path, data in blobs.items():
            archive.writestr(path, data)


write_fixture(
    "simple-table",
    {
        "documentId": "doc-simple",
        "sheets": [
            {
                "sheetId": "sheet-1",
                "name": "Sheet 1",
                "tables": [
                    {
                        "tableId": "table-1",
                        "name": "Table 1",
                        "rowCount": 4,
                        "columnCount": 3,
                        "merges": [],
                        "cells": [
                            {"row": 0, "column": 0, "stringValue": "Name"},
                            {"row": 0, "column": 1, "stringValue": "Value"},
                            {"row": 1, "column": 0, "stringValue": "Answer"},
                            {"row": 1, "column": 1, "numberValue": 42},
                            {"row": 2, "column": 0, "stringValue": "Enabled"},
                            {"row": 2, "column": 1, "boolValue": True}
                        ]
                    }
                ]
            }
        ]
    },
    {
        "Index/Document.iwa": make_blob(
            [
                (1, 1001, b"doc"),
                (2, 1002, b"sheet"),
                (3, 1003, b"table"),
            ]
        )
    }
)

write_fixture(
    "merged-cells",
    {
        "documentId": "doc-merged",
        "sheets": [
            {
                "sheetId": "sheet-merged",
                "name": "Merged Sheet",
                "tables": [
                    {
                        "tableId": "table-merged",
                        "name": "Merged Table",
                        "rowCount": 5,
                        "columnCount": 5,
                        "merges": [
                            {
                                "startRow": 0,
                                "endRow": 1,
                                "startColumn": 0,
                                "endColumn": 1
                            }
                        ],
                        "cells": [
                            {"row": 0, "column": 0, "stringValue": "Merged Title"}
                        ]
                    }
                ]
            }
        ]
    },
    {
        "Index/Merged.iwa": make_blob(
            [
                (11, 1001, b"doc"),
                (12, 1002, b"sheet"),
                (13, 1003, b"table"),
            ]
        )
    }
)

write_fixture(
    "styled-cells",
    {
        "documentId": "doc-styled",
        "sheets": [
            {
                "sheetId": "sheet-style",
                "name": "Styled Sheet",
                "tables": [
                    {
                        "tableId": "table-style",
                        "name": "Styled Table",
                        "rowCount": 6,
                        "columnCount": 4,
                        "merges": [],
                        "cells": [
                            {"row": 0, "column": 0, "stringValue": "Amount"},
                            {"row": 1, "column": 0, "stringValue": "Q1"},
                            {"row": 1, "column": 1, "numberValue": 1200.5},
                            {"row": 2, "column": 0, "stringValue": "Q2"},
                            {"row": 2, "column": 1, "numberValue": 1325.75}
                        ]
                    }
                ]
            }
        ]
    },
    {
        "Index/Styles.iwa": make_blob(
            [
                (21, 1001, b"doc"),
                (22, 1002, b"sheet"),
                (23, 1003, b"table"),
                (24, 2001, b"style"),
            ]
        )
    }
)

write_fixture(
    "multi-sheet",
    {
        "documentId": "doc-multi",
        "sheets": [
            {
                "sheetId": "sheet-a",
                "name": "Sheet A",
                "tables": [
                    {
                        "tableId": "table-a1",
                        "name": "Table A1",
                        "rowCount": 3,
                        "columnCount": 3,
                        "merges": [],
                        "cells": [
                            {"row": 0, "column": 0, "stringValue": "A1"},
                            {"row": 1, "column": 1, "numberValue": 10}
                        ]
                    }
                ]
            },
            {
                "sheetId": "sheet-b",
                "name": "Sheet B",
                "tables": [
                    {
                        "tableId": "table-b1",
                        "name": "Table B1",
                        "rowCount": 2,
                        "columnCount": 2,
                        "merges": [],
                        "cells": [
                            {"row": 0, "column": 0, "stringValue": "B1"}
                        ]
                    },
                    {
                        "tableId": "table-b2",
                        "name": "Table B2",
                        "rowCount": 7,
                        "columnCount": 5,
                        "merges": [],
                        "cells": [
                            {"row": 0, "column": 0, "stringValue": "Flag"},
                            {"row": 0, "column": 1, "boolValue": False}
                        ]
                    }
                ]
            }
        ]
    },
    {
        "Index/Document.iwa": make_blob([(31, 1001, b"doc")]),
        "Index/Sheets.iwa": make_blob([(32, 1002, b"sheet-a"), (33, 1002, b"sheet-b")]),
        "Index/Tables.iwa": make_blob([(34, 1003, b"table-a1"), (35, 1003, b"table-b1")]),
    }
)

print("Generated fixtures in", FIXTURES)
