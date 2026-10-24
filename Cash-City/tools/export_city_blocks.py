"""Export existing geometry as deterministic, independently rebuildable block plans."""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SECTOR = re.compile(r"-?\d+_-?\d+\Z")


def serialize(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"),
                       allow_nan=False) + "\n").encode("utf-8")


def make_blocks(records, sectors=None):
    """Retain source records verbatim, including unknown provenance fields and order."""
    if not isinstance(records, list):
        raise ValueError("Geometry must be an ordered list")
    grouped = {}
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            raise ValueError(f"Record {index} must be an object")
        sector = record.get("sector")
        if not isinstance(sector, str) or not SECTOR.fullmatch(sector):
            raise ValueError(f"Record {index} has an unsafe/missing sector")
        if record.get("cls", "Part") not in ("Part", "WedgePart"):
            raise ValueError(f"Record {index} needs an explicit template adapter")
        block = grouped.setdefault(sector, {"id": "Sector_" + sector, "records": [],
                                           "sourceIndices": [], "schemaVersion": 1})
        block["records"].append(record)
        block["sourceIndices"].append(index)
    selected = set(grouped) if sectors is None else set(sectors)
    unknown = selected - grouped.keys()
    if unknown:
        raise ValueError("Unknown sectors: " + ", ".join(sorted(unknown)))
    return {sector: grouped[sector] for sector in sorted(selected)}


def export_blocks(source, output, sectors=None):
    # Complete serialization before writing, so invalid inputs never partially export.
    records = json.loads(Path(source).read_text(encoding="utf-8"))
    blocks = make_blocks(records, sectors)
    payloads = {key: serialize(block) for key, block in blocks.items()}
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = {"written": [], "unchanged": [], "records": 0, "sha256": {}}
    for sector, payload in payloads.items():
        path = output / (blocks[sector]["id"] + ".json")
        result["records"] += len(blocks[sector]["records"])
        result["sha256"][sector] = hashlib.sha256(payload).hexdigest()
        if path.exists() and path.read_bytes() == payload:
            result["unchanged"].append(sector)
            continue
        # Replace one file atomically; unrelated sectors and hand-authored files untouched.
        temporary = path.with_suffix(".json.tmp")
        with temporary.open("xb") as stream:
            stream.write(payload)
        temporary.replace(path)
        result["written"].append(sector)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "data/geometry.json")
    parser.add_argument("--output", type=Path, default=ROOT / "data/city_blocks")
    parser.add_argument("--sector", action="append", help="Repeat to export selected sectors only; use --sector=-1_0 for negatives")
    args = parser.parse_args()
    try:
        result = export_blocks(args.source, args.output, args.sector)
    except (ValueError, OSError) as error:
        parser.exit(1, f"Export failed: {error}\n")
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
