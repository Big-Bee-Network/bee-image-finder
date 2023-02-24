# Bee Image Finder

This repository helps to generate cc0 licensed images of (type) specimen in the Big Bee collection family. 

Checkout the [samples](#animated-gifs).

## Prerequisites

 * linux, mac os x, or Windows Subsystem for Linux https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux
 * Preston https://github.com/bio-guoda/preston
 * zip
 * jq 
 * parallel

## Usage


```
./find-images [catalog number] [dwca URL]
```

where 

`catalog number` is the catalog number of the specimen you'd like to generate an image sequence for.

and

`dwca/rss URL` is location of the Darwin Core Archive or RSS feed of Darwin Core Archives that includes a specimen with the catalog number 

This can be combines with other programs like `cat` to generate image sequences for a list of catalogNumbers:

```
cat catalogNumbers.txt\
 | xargs -L1 ./find-images.sh 
```

or, if you'd like to do it in parallel:

```
cat catalogNumbers.txt\
 | parallel ./find-images.sh {1}
```
Note that the catalog numbers are consist of a type specimen in bee families Andrenidae, Apidae, Colletidae, Halictidae, Megachilidae, Melittidae, and Stenotritidae, in California Academy of Sciences Entomology Type collections that had images on 2023-02-24. 



## Results

If found, images of type specimen will be available in folder `dist/[catalog number]/` . 

## Publication

The distributions are optimized for publication to Zenodo. See https://github.com/jhpoelen/zenodo-upload for ways to do this programmatically.

## Example

```
./find-and-get-image "UCSB-IZC00012194" "https://library.big-bee.net/portal/content/dwca/UCSB-IZC_DwC-A.zip"
```

produced the following flat (Zenodo compatible) output in the `dist/UCSB-IZC00012194` folder as shown below.

Note that the long cryptic filenames help for machines to discover and verify content using the Preston command-line tool and associated packaging methods. For more information, see https://github.com/bio-guoda/preston or related publications:

MJ Elliott, JH Poelen, JAB Fortes (2020). Toward Reliable Biodiversity Dataset References. Ecological Informatics. https://doi.org/10.1016/j.ecoinf.2020.101132

Elliott, M. J., Poelen, J. H., & Fortes, J. (2022, August 29). Signed Citations: Making Persistent and Verifiable Citations of Digital Scientific Content. https://doi.org/10.31222/osf.io/wycjn
