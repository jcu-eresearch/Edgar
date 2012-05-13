#!/usr/bin/python

import sys
import csv
import os
import glob
from datetime import datetime
import logging.handlers


def main():
    models_base_path = os.path.join('/', 'scratch', 'jc155857', 'CostaRica', 'models')
    species_listing = os.listdir(models_base_path)

    for infile in species_listing:
        # print infile
        model_csv_file = os.path.join(models_base_path, infile, 'outputs', 'maxentResults.csv')
        # print model_csv_file
        reader = csv.reader(open(model_csv_file, "rb"))
        header = reader.next()
        content = reader.next()
        col_pos = 0;
        for column in header:
            if column == 'Equate entropy of thresholded and original distributions logistic threshold':
                #print column
                #print col_pos
                break;
            col_pos += 1
        threshold = content[col_pos]
        print infile + "," + threshold
