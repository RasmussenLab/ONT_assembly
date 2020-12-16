#!/bin/bash

while read line ; do
  if [ ${line:0:1} == ">" ] ; then
    filename=$(echo "$line" | cut -d ":" -f1 | tr -d ">")
    touch $2/"$filename".fasta
    echo "$line" >> $2/"${filename}".fasta
  else
    echo "$line" >> $2/"${filename}".fasta
  fi
done < $1
