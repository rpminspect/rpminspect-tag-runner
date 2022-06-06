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
f = open(cache_file,'w+')
if f.tell() != 0:
    data = json.load(f)
else:
    data = {}

# Check if we have it already
if nvr in data:
    print(data[nvr])
    sys.exit(0)

# Fetch from koji, cache it, and return it
koji_url = "https://kojihub.stream.centos.org/kojihub"
session = koji.ClientSession(koji_url)
result = session.getBuild(nvr)['package_name']
data[nvr] = result
f.write(str(data))
f.close()
print(result)

# all done
sys.exit(0)
