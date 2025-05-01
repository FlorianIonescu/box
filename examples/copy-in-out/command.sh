#!/usr/bin/env bash

# copies in the example.txt
# runs a few commands and pipes their outputs into lsla.txt
# copies that file out of the container

./../../box.sh -e alpine-latest -m mappings.json -c "pwd >> lsla.txt; cat example.txt >> lsla.txt; ls -la >> lsla.txt; date >> lsla.txt"