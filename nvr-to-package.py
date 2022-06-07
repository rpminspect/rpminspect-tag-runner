#!/usr/bin/python3
import json
import koji
import sys

# TODO: getopts would be nice
if len(sys.argv) != 2:
    print("ERROR: please provide an nvr.")
    sys.exit(1)
nvr = sys.argv[1]

# Load or initialize our cache as needed
cache_file = 'nvr-to-package.json'
# Exceptions could be missing file or invalid file
# The cache is not vital so we can start from scratch
# as needed
try:
    with open(cache_file, 'r') as f:
        data = json.loads(f.read())
except:
    data = {}

# Check if we have it already
if nvr in data:
    print(data[nvr])
    sys.exit(0)

# Fetch from koji and abort if missing
koji_url = "https://kojihub.stream.centos.org/kojihub"
session = koji.ClientSession(koji_url)
try:
    result = session.getBuild(nvr)['package_name']
except:
    print(f"Failed to find package name for {nvr}")
    sys.exit(1)

# Cache it and return it
data[nvr] = result
with open(cache_file, 'w') as f:
    f.write(json.dumps(data))
print(result)

# all done
sys.exit(0)
