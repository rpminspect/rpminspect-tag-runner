#!/usr/bin/python3
import koji
import operator
from time import sleep

koji_url = "https://kojihub.stream.centos.org/kojihub"
koji_tag = "c9s-pending"
print('Starting koji session...', end='')
session = koji.ClientSession(koji_url)
print('done.')
print(f'Discovering packages in {koji_tag}...', end='')
list_tagged_packages = session.listTagged(koji_tag, inherit=True, latest=True)
print('done.')
build_sizes = {}
for package in list_tagged_packages:
    builds = None
    nvr = package['nvr']
    print(f'Finding size for {nvr}...', end='')
    while not builds:
        try:
            builds = session.listBuildRPMs(package['build_id'])
        except:
            print('failed.')
            print('Retrying...', end='')
    size = 0
    for build in builds:
        size += build['size']
    build_sizes[nvr] = size
    print('done.')
    #sleep(0.5)

# https://www.w3resource.com/python-exercises/dictionary/python-data-type-dictionary-exercise-1.php
results = dict(sorted(build_sizes.items(), key=operator.itemgetter(1),reverse=True))

for key in results:
    print(key)
