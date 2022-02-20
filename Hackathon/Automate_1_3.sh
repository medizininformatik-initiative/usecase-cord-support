#!/bin/bash
echo "CORD Hackathon"
BASE_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=%s\n", "'$prefix'",vn, $2, $3);
      }
   }'
}
echo

export $(parse_yaml $BASE_DIR/config/conf.yml)
cd ${BASE_DIR}
path_script1="${BASE_DIR}/Team1_FHIRCrackR/script1.r"
Rscript $path_script1
echo
echo "Script 1 completed"
echo
path_script2="${BASE_DIR}/Team2_Distance/script2.r"
Rscript $path_script2
echo
echo "Script 2 completed"
echo
path_script3=${BASE_DIR}"/"${default_distance_result}
echo
echo
java -jar ${BASE_DIR}"/Team3_Aggregation/"script3.jar $path_script3
echo
echo "Script 3 completed"
echo
echo "starting visualization server on http://localhost:3838"
echo
