#!/bin/bash
f="Finance Planner – Refined Home.pdf"
for i in $(seq 1 61); do
  t=$(pdftotext -f $i -l $i "$f" - | grep -v '^$' | head -4 | tr '\n' '|')
  echo "$i: $t"
done
