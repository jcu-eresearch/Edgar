#!/usr/bin/env python3
import glob

# For use with --files-from argument for Rclone
# This suits Edgar's structure with is
# SPECIESNAME/{occurrences|projected-distributions}/[2nd-to-latest-file-is-the-latest].zip
for folder in glob.glob('*'):
    occurrences = glob.glob(folder + '/occurrences/*')
    projected_distributions = glob.glob(folder + '/projected-distributions/*')
    if not 'latest' in occurrences[-1] and not 'latest' in projected_distributions[-1]:
        print(f'No latest in {folder}!')
        exit(1)

    print(folder + '/metadata.json')
    print(occurrences[-2])
    print(projected_distributions[-2])
