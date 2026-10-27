#!/usr/bin/env python3
"""Print xcresult failures and preserve diagnostics without changing test status."""
import json
from pathlib import Path
import subprocess
import sys
import tarfile


def unwrap(value):
    if isinstance(value, list):
        return [unwrap(item) for item in value]
    if isinstance(value, dict):
        if "_value" in value:
            return value["_value"]
        if value.get("_type", {}).get("_name") == "Array":
            return unwrap(value.get("_values", []))
        return {key: unwrap(item) for key, item in value.items() if key != "_type"}
    return value


def walk(value):
    if isinstance(value, dict):
        yield value
        for item in value.values():
            yield from walk(item)
    elif isinstance(value, list):
        for item in value:
            yield from walk(item)


def report(bundle):
    output = Path("build/test-diagnostics") / bundle.stem
    output.mkdir(parents=True, exist_ok=True)
    # Preserve bundle layout and all attachments, even if extraction fails.
    with tarfile.open(output / (bundle.name + ".tar.gz"), "w:gz", compresslevel=1) as archive:
        archive.add(bundle, arcname=bundle.name)
    print(f"Result bundle: {bundle}", flush=True)

    def read_object(name, reference=None):
        # Xcode 26.6 supports this API, including assertion source URLs.
        command = ["xcrun", "xcresulttool", "get", "object", "--legacy",
                   "--path", str(bundle), "--format", "json"]
        if reference:
            command += ["--id", reference]
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode:
            print(f"WARNING: xcresult read failed: {result.stderr.strip()}")
            return {}
        data = unwrap(json.loads(result.stdout))
        (output / name).write_text(json.dumps(data, indent=2) + "\n")
        return data

    result = read_object("result.json")
    issues = result.get("issues", {})
    failures = issues.get("testFailureSummaries", [])
    if not failures:
        print("No test failure summaries found (check build errors or incomplete results).")
    for failure in failures + issues.get("errorSummaries", []):
        print(f"FAILED: {failure.get('testCaseName', 'Build or test infrastructure')}")
        print(f"Assertion: {failure.get('message', '(no message)')}")
        print(f"Source: {failure.get('documentLocationInCreatingWorkspace', {}).get('url', '(unavailable)')}")

    index = 0
    for action in result.get("actions", []):
        reference = action.get("actionResult", {}).get("testsRef", {}).get("id")
        if not reference:
            continue
        index += 1
        tests = read_object(f"tests-{index}.json", reference)
        for test in walk(tests):
            reference = test.get("summaryRef", {}).get("id")
            if not reference or test.get("testStatus") != "Failure":
                continue
            index += 1
            print(f"Failed-test activity: {test.get('identifier', '(unknown test)')}")
            summary = read_object(f"failed-test-{index}.json", reference)
            for activity in walk(summary):
                if activity.get("title"):
                    print(f"  {activity['title']}")
    exported = subprocess.run([
        "xcrun", "xcresulttool", "export", "attachments", "--path", str(bundle),
        "--output-path", str(output / "attachments"), "--only-failures",
    ])
    if exported.returncode:
        print("WARNING: attachment export failed; original attachments remain in the archived xcresult.")


if __name__ == "__main__":
    marker = Path("build/ios-result-path.txt")
    if len(sys.argv) > 1:
        bundle = Path(sys.argv[1])
    elif marker.exists():
        bundle = Path(marker.read_text().strip())
    else:
        print("WARNING: no result path recorded; testing may have stopped before xcodebuild.")
        sys.exit(0)
    if not bundle.is_dir():
        print(f"WARNING: result bundle not found: {bundle}")
        sys.exit(0)
    report(bundle)
