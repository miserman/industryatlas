library(community)

outdir <- "docs/data/"
dir.create(outdir, FALSE, TRUE)

#
# ingest data
#

# map and county metadata
map_file <- "docs/counties_2010.geojson"
if (file.exists(map_file)) {
  map <- sf::st_read(map_file)
} else {
  map <- sf::st_read(paste0(
    "https://raw.githubusercontent.com/DISSC-yale/industryatlas",
    "/refs/heads/main/public/counties_2010.geojson"
  ))
  # remove discontinuous states
  map <- map[!grepl("Alaska|Hawaii|Puerto", map$region_name), ]
  sf::st_write(map, map_file)
}

# employment data
basedir <- "../original/data/"
dir.create(basedir, FALSE, TRUE)

zipfile <- paste0(basedir, "/efsy_panel_naics.csv.zip")
if (!file.exists(zipfile)) {
  download.file(
    "http://fpeckert.me/cbp/Imputed%20Files/efsy_panel_naics.csv.zip",
    zipfile
  )
}
data <- vroom::vroom(zipfile, col_types = "iicdcd")
data$geoid <- paste0(
  formatC(data$fipstate, width = 2, flag = 0),
  formatC(data$fipscty, width = 3, flag = 0)
)
data$sector <- substring(data$naics12, 1, 2)
data$sector[data$sector %in% c("32", "33")] <- "31"
data$sector[data$sector == "45"] <- "44"
data$sector[data$sector == "49"] <- "48"
data$sector[data$sector %in% c("95", "99")] <- "92"

totals <- dplyr::group_by(data, year, geoid) |>
  dplyr::summarize(value = as.integer(round(sum(emp, na.rm = TRUE))))
totals$sector <- "10"
aggregated <- rbind(
  totals[, c("year", "geoid", "sector", "value")],
  dplyr::group_by(data, year, geoid, sector) |>
    dplyr::summarize(value = as.integer(round(sum(emp, na.rm = TRUE)))),
)
aggregated$region_type = "county"

tallfile <- paste0(basedir, "county.csv.xz")
vroom::vroom_write(aggregated, tallfile, ",")
data_reformat_sdad(
  tallfile, outdir,
  value_name = "sector",
  metadata = map
)

#
# build data and site
#

data_add(
  c(county = "county.csv.xz"),
  list(
    ids = list(variable = "ID", map = "data/entity_info.json"),
    time = "time",
    variables = list(
      "10" = list(
        measure = "10",
        type = "integer",
        full_name = "Total Employment",
        short_name = "Total Employment",
        description = "Number employed across sectors.",
        statement = "There were {value} people employed in {region_name} in {data.time}.",
        citations = "eckert20",
        sources = list(list(
          name = "County Business Patterns Database",
          url = "https://www.fpeckert.me/cbp/",
          location = "Final Industry Concordance File",
          location_url = "http://fpeckert.me/cbp/Imputed%20Files/efsy_final_concordances.zip",
          date_accessed = "2025-04-10"
        ))
      ),
      "{variant.name}" = list(
        measure = "{variant.name}",
        type = "integer",
        full_name = "{variant} Employment",
        short_name = "{variant}",
        description = "Number employed in the {variant} ({variant.name}) sector.",
        statement = "There were {value} people employed in the {variant} sector in {region_name} in {data.time}.",
        variants = list(
          "11" = list(default = "Agriculture, Forestry, Fishing and Hunting"),
          "21" = list(default = "Mining, Quarrying, and Oil and Gas Extraction"),
          "22" = list(default = "Utilities"),
          "23" = list(default = "Construction"),
          "31" = list(default = "Manufacturing"),
          "42" = list(default = "Wholesale Trade"),
          "44" = list(default = "Retail Trade"),
          "48" = list(default = "Transportation and Warehousing"),
          "51" = list(default = "Information"),
          "52" = list(default = "Finance and Insurance"),
          "53" = list(default = "Real Estate and Rental and Leasing"),
          "54" = list(default = "Professional, Scientific, and Technical Services"),
          "55" = list(default = "Management of Companies and Enterprises"),
          "56" = list(default = "Administrative and Support and Waste Management and Remediation Services"),
          "61" = list(default = "Educational Services"),
          "62" = list(default = "Health Care and Social Assistance"),
          "71" = list(default = "Arts, Entertainment, and Recreation"),
          "72" = list(default = "Accommodation and Food Services"),
          "81" = list(default = "Other Services"),
          "92" = list(default = "Public Administration")
        ),
        citations = "eckert20",
        sources = list(list(
          name = "County Business Patterns Database",
          url = "https://www.fpeckert.me/cbp/",
          location = "Final Industry Concordance File",
          location_url = "http://fpeckert.me/cbp/Imputed%20Files/efsy_final_concordances.zip",
          date_accessed = "2025-04-10"
        ))
      ),
      "_references" = list(
        eckert20 = list(
          title = "Imputing missing values in the US Census Bureau's county business patterns",
          author = list(
            list(given = "Fabian", family = "Eckert"),
            list(given = "Teresa", family = "Fort"),
            list(given = "Peter", family = "Schott"),
            list(given = "Natalie", family = "Yang")
          ),
          volume = "No. w26632",
          year = "2020",
          journal = "National Bureau of Economic Research",
          doi = "10.3386/w26632"
        )
      )
    )
  ),
  dir = outdir
)
site_build(".", version = "dev", serve = TRUE, options = list(
  theme_dark = TRUE, polygon_outline = 1
))
