# Any copyright is dedicated to the Public Domain.
# http://creativecommons.org/publicdomain/zero/1.0/

# Creates the precomplete file containing the remove and rmdir application
# update instructions which is used to remove files and directories that are no
# longer present in a complete update. The current working directory is used for
# the location to enumerate and to create the precomplete file.

# This file is a slightly adapted version of Mozilla's createprecomplete.py
# which my be found here:
# https://mxr.mozilla.org/mozilla-central/source/config/createprecomplete.py
# Done by JonDos GmbH 2013.

import sys
import os

def get_build_entries(root_path):
    """ Iterates through the root_path, creating a list for each file and
        directory. Excludes any path starting with "extensions" or
        "distribution" and paths ending with "channel-prefs.js". We exclude
        paths starting with "Data" as well as we do not want to touch the user's
        profile directory (yet)
    """
    rel_file_path_set = set()
    rel_dir_path_set = set()
    for root, dirs, files in os.walk(root_path):
        for file_name in files:
            parent_dir_rel_path = root[len(root_path)+1:]
            rel_path_file = os.path.join(parent_dir_rel_path, file_name)
            rel_path_file = rel_path_file.replace("\\", "/")
            if not (rel_path_file.startswith("distribution/") or
                    rel_path_file.startswith("extensions/") or
                    rel_path_file.startswith("Data/") or
                    rel_path_file.endswith("channel-prefs.js")):
                rel_file_path_set.add(rel_path_file)

        for dir_name in dirs:
            parent_dir_rel_path = root[len(root_path)+1:]
            rel_path_dir = os.path.join(parent_dir_rel_path, dir_name)
            rel_path_dir = rel_path_dir.replace("\\", "/")+"/"
            if not (rel_path_dir.startswith("distribution/") or
                    rel_path_dir.startswith("Data/") or
                    rel_path_dir.startswith("extensions/")):
                rel_dir_path_set.add(rel_path_dir)

    rel_file_path_list = list(rel_file_path_set)
    rel_file_path_list.sort(reverse=True)
    rel_dir_path_list = list(rel_dir_path_set)
    rel_dir_path_list.sort(reverse=True)

    return rel_file_path_list, rel_dir_path_list

def generate_precomplete(root_path):
    """ Creates the precomplete file containing the remove and rmdir
        application update instructions. The given directory is used
        for the location to enumerate and to create the precomplete file.
    """
    # If inside a Mac bundle use the root of the bundle for the path.
    if os.path.basename(root_path) == "MacOS":
        root_path = os.path.abspath(os.path.join(root_path, '../../'))

    rel_file_path_list, rel_dir_path_list = get_build_entries(root_path)
    precomplete_file_path = os.path.join(root_path,"precomplete")
    # open in binary mode to prevent OS specific line endings.
    precomplete_file = open(precomplete_file_path, "wb")
    for rel_file_path in rel_file_path_list:
        precomplete_file.writelines("remove \""+rel_file_path+"\"\n")

    for rel_dir_path in rel_dir_path_list:
        precomplete_file.writelines("rmdir \""+rel_dir_path+"\"\n")

    precomplete_file.close()

if __name__ == "__main__":
    generate_precomplete(os.path.join(os.getcwd(), 'JonDoBrowser'))
