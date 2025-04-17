# Industry Atlas

Site to display imputed U.S. employment by industry and county.

This is a rework of `industryatlas.org` ([kenny101/industryatlas](https://github.com/kenny101/industryatlas)) with data served statically.

## Data

The [build.R](build.R) script downloads original data from [fpeckert.me/cbp](https://www.fpeckert.me/cbp/),
and reformats it to [public/data](docs/data/county.csv.xz).

## Run
```R
# remotes::install_github("uva-bi-sdad/community")
library(community)

# from the site directory:
site_build(".")
```
