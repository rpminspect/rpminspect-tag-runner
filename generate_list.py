#!/usr/bin/python3

# Create list of NVRs to test

import argparse
import getpass
import koji
import logging
import sys

koji_tag='c9s-pending'
filename = 'list.txt'
koji_url = "https://kojihub.stream.centos.org/kojihub"

# Set logger
# Username filter
# (to add current username to logging format)
#
class UsernameFilter(logging.Filter):
    def filter(self, record):
        record.username = getpass.getuser()
        return True

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addFilter(UsernameFilter())
handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(username)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)


def get_arguments(koji_tag, filename):
    parser = argparse.ArgumentParser()
    parser.add_argument('--koji-tag', dest='koji_tag', type=str, nargs='?', const=koji_tag, default=koji_tag, help='Koji tag')
    parser.add_argument('--file', dest='filename', type=str, nargs='?', const=filename,  default=filename, help='File name for saved NVRs')
    arguments = parser.parse_args()
    logger.info(f"Got arguments: {arguments}")
    return arguments


def get_list_tagged_packages(koji_url, koji_tag):
    logger.info("Start getting list of tagged packages from Koji tag {koji_tag}")
    session = koji.ClientSession(koji_url)
    list_tagged_packages = session.listTagged(koji_tag, inherit=True, latest=True)
    logger.info(f"Total {len(list_tagged_packages)} tagged packages in the tag {koji_tag}")
    return list_tagged_packages


def save_to_file(file_name, list_tagged_packages):
    logger.info(f"Saving list of tagged packages to the file {file_name}")
    with open(file_name, 'w') as file:
        for tagged_package in list_tagged_packages:
            file.write(f"{tagged_package['nvr']}\n")
    logger.info(f"All packages was saved to the file {file_name}")


def main():
    arguments = get_arguments(koji_tag=koji_tag, filename=filename)
    list_tagged_packages = get_list_tagged_packages(koji_url=koji_url, koji_tag=arguments.koji_tag)
    save_to_file(file_name=arguments.filename, list_tagged_packages=list_tagged_packages)


if __name__ == "__main__":
    main()
