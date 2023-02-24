#!/bin/bash
#
# ./create-imageseq.sh [DWC-A URL] [UCSB catalog number] 
#
# Make an animated gif bee movie using UCSB Naming Convention
# and archive their dependencies in a Preston archive.
#

set -xe

CATALOG_NUMBER=${1:-"UCSB-IZC00012194"}
DWC_URL=${2:-"https://library.big-bee.net/portal/content/dwca/UCSB-IZC_DwC-A.zip"}
IMAGE_SEQUENCE_TAG="_3d_"

DIST_DIR=dist/${CATALOG_NUMBER}
mkdir -p "${DIST_DIR}"

TMP_DIR="tmp/${CATALOG_NUMBER}"
mkdir -p "${TMP_DIR}"

OPTS="--data-dir $TMP_DIR/data"


check_dependencies() {
  preston version
  ffmpeg -version | head -n1
  jq --version
  which zip
  parallel --version | head -n1
} 

track_collection_extract_images() {

  preston track ${OPTS} "${DWC_URL}"\
  | preston dwc-stream ${OPTS}\
  | grep "${CATALOG_NUMBER}"\
  | grep ${IMAGE_SEQUENCE_TAG}\
  | jq --raw-output '.["http://rs.tdwg.org/ac/terms/accessURI"]'\
  > ${TMP_DIR}/image-urls.txt

  NUMBER_OF_IMAGES=$(cat ${TMP_DIR}/image-urls.txt | wc -l)

  if [ "${NUMBER_OF_IMAGES}" -gt 0 ]
  then 
    cat "${TMP_DIR}/image-urls.txt" | xargs -L25 preston track ${OPTS}
  fi
}

build_image_sequence_archive() {

  preston alias ${OPTS} --log tsv\
  | grep "${CATALOG_NUMBER}"\
  | grep jpg\
  | cut -f1,3\
  | sort\
  | uniq\
  | cut -f2\
  | tee ${TMP_DIR}/image-hashes.txt\
  | nl -n rz\
  | parallel --col-sep '\t' "preston cat ${OPTS} {2} > ${TMP_DIR}/{1}-${CATALOG_NUMBER}.jpg"

  local BEE_IMAGE_ZIP="${DIST_DIR}/imageseq.zip"

  zip --junk-paths "${BEE_IMAGE_ZIP}" ${TMP_DIR}/*.jpg

  BEE_GIF="${DIST_DIR}/imageseq.gif"

  # compile the images into an animated gif 
  ffmpeg -y -i "${TMP_DIR}/%06d-${CATALOG_NUMBER}.jpg" -vf scale=320:240 "${BEE_GIF}"

  # append the movie to the Preston archive
  BEE_GIF_HASH=$(preston track ${OPTS} "file://$PWD/${BEE_GIF}" | grep hasVersion | grep -o -P "hash://sha256/[a-f0-9]{64}")
  BEE_IMAGE_ZIP_HASH=$(preston track ${OPTS} "file://$PWD/${BEE_IMAGE_ZIP}" | grep hasVersion | grep -o -P "hash://sha256/[a-f0-9]{64}")

  # record the content of this script
  SCRIPT_HASH=$(preston track ${OPTS} "file://$PWD/$0" | grep hasVersion | grep -o -P "hash://sha256/[a-f0-9]{64}")

  echo "<$BEE_GIF_HASH> <http://www.w3.org/ns/prov#wasGeneratedBy> <$SCRIPT_HASH> ."\
  | preston process ${OPTS}

  cat ${TMP_DIR}/image-hashes.txt\
  | xargs -I{} echo "<$BEE_GIF_HASH> <http://www.w3.org/ns/prov#wasDerivedFrom> <{}> ."\
  | preston process ${OPTS}
  
cat ${TMP_DIR}/image-hashes.txt\
  | xargs -I{} echo "<$BEE_IMAGE_ZIP_HASH> <http://www.w3.org/ns/prov#wasDerivedFrom> <{}> ."\
  | preston process ${OPTS} 
}

generate_label() {
  preston label ${OPTS} > ${DIST_DIR}/label.png
}

check_dependencies
track_collection_extract_images
build_image_sequence_archive
generate_label

preston export ${OPTS} -p directoryDepth0 ${DIST_DIR} 

append_readme() {
  tee --append ${DIST_DIR}/README.md
}

echo -e "# ${CATALOG_NUMBER}\nThis package contains image sequences exacted from specimen with catalog number ${CATALOG_NUMBER} as extract from ${DWC_URL} using tools like Preston, zip and ffmpeg.\n ## Provenance\n" | append_readme

preston history ${OPTS} | append_readme 

echo -e "\n## Content Aliases\n" | append_readme 

preston alias ${OPTS} | append_readme

echo Image sequence package for ${CATALOG_NUMBER} available in [${PWD}/${DIST_DIR}] .
