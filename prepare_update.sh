#!/bin/bash   
rm controls_TibberConnect.txt
find ./FHEM -type f \( ! -iname ".*" \) -print0 | while IFS= read -r -d '' f; 
  do
   echo "DEL ${f}" >> controls_TibberConnect.txt
   out="UPD "$(stat -f "%Sm" -t "%Y-%m-%d_%T" $f)" "$(stat -f%z $f)" ${f}"
   echo ${out//.\//} >> controls_TibberConnect.txt
done

# CHANGED file
echo "FHEM AbtractTable last changes:" > CHANGED
echo $(date +"%Y-%m-%d") >> CHANGED
echo " - $(git log -1 --pretty=%B)" >> CHANGED
