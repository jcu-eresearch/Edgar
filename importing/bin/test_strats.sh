#!/bin/bash

BIN_DIR="$(dirname "$0")"

test_strat() {
  echo "Testing strategy: $1"

  python "$BIN_DIR/fetch_occur_csv.py" \
    --speed-info \
    --strategy "$1" \
    "$2" \
    > "data/$1-output.csv" \
    2> "data/$1-info.txt"

  if [ $? -eq 0 ] ; then
    wc -l "data/$1-output.csv"
  else
    echo "FAILED"
  fi
}


if [ $# -eq 1 ] ; then
  mkdir -p data
  test_strat 'facet' $1
  test_strat 'search' $1
  #download strategy sucks. by far the slowest.
  #test_strat 'download' $1
else
  echo "Usage: $0 LSID"
fi
