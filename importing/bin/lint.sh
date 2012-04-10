IFS=$'\n'
for FILENAME in $(find . -iname "*.py") ; do
  pep8 --count --show-source "$FILENAME"
done
