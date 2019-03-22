##############################################
# UK FOOD HYGIENE RATING - Download Shops
##############################################
# source data main page: http://ratings.food.gov.uk/open-data
# example URL for LAD XXX: http://ratings.food.gov.uk/OpenDataFiles/FHRSXXXen-GB.xml

# load packages
pkgs <- c('data.table', 'fst', 'rgdal', 'RMySQL', 'rvest', 'XML')
invisible(lapply(pkgs, require, character.only = TRUE))

# lads <- read.fst('data/lads', as.data.table = TRUE)
# shops <- read.fst('data/shops', as.data.table = TRUE)

# download metadata about Local Authorities
# - text for the first three columns ('name', 'updated_at', 'tot_shops'), link for the last one (url)
# - delete Welsh duplicates (cy in url)
lads <- read_html('http://ratings.food.gov.uk/open-data')
lads <- cbind(
            lads %>%
                html_nodes('td:nth-child(1) , td:nth-child(2) , td:nth-child(3)') %>% 
                html_text() %>% 
                matrix(byrow = TRUE, ncol = 3),
            lads %>%
                html_nodes('#openDataStatic a') %>%
                html_attr('href') %>% 
                matrix()
    ) %>% 
    as.data.table() %>% 
    setnames(c('name', 'updated_at', 'tot_shops', 'url')) %>% 
    subset(!grepl('cy', url)) %>% 
    setorder(url)

# clean and transform
lads[, `:=`(
    name = trimws(name),
    updated_at = as.Date(substr(trimws(updated_at), 1, 10), '%d/%m/%Y'),
    tot_shops = as.numeric(gsub('[^0-9]', '', tot_shops)),
    lad_id = gsub('[^0-9]', '', url)
)]

# create empty structure to contain data about shops
cols <- c(
  'lad_id', 'shop_id', 'shop_ladid', 'name', 'sector', 'sector_id', 'postcode', 
  'rating', 'updated_at', 'score_H', 'score_S', 'score_C', 'x_lon', 'y_lat'
)
shops <- setnames( data.table(matrix(nrow = 0, ncol = length(cols))), cols)

# download shops data, keeping only the required fields
print(paste('Processing local authorities...'))
tmp <- tempfile()
for(idx in 1:nrow(lads)){
    message('Downloading file n. ', idx, ' out of ', nrow(lads))
    download.file(lads[idx, url], destfile = tmp)
    message('Processing...')
    y <- xmlToList(xmlTreeParse(tmp))[[2]]
    if(!is.null(dim(y))){
        message('uh-oh... XML file for lad with id ', lads[idx, lad_id], ' has an error... :`-(')
        next
    }
    message('Adding ', length(y), ' records...')
    shops <- rbindlist(list(
                        shops,
                        as.data.table(cbind(
                            lapply(y, '[[', 'LocalAuthorityCode'), 
                            lapply(y, '[[', 'FHRSID'), 
                            lapply(y, '[[', 'LocalAuthorityBusinessID'), 
                            lapply(y, '[[', 'BusinessName'),
                            lapply(y, '[[', 'BusinessType'), 
                            lapply(y, '[[', 'BusinessTypeID'),
                            lapply(y, '[[', 'PostCode'),
                            lapply(y, '[[', 'RatingValue'),
                            lapply(y, '[[', 'RatingDate'),
                            lapply(lapply(y, '[[', 'Scores'), '[[', 'Hygiene'),
                            lapply(lapply(y, '[[', 'Scores'), '[[', 'Structural'),
                            lapply(lapply(y, '[[', 'Scores'), '[[', 'ConfidenceInManagement'),
                            lapply(lapply(y, '[[', 'Geocode'), '[[', 'Longitude'),
                            lapply(lapply(y, '[[', 'Geocode'), '[[', 'Latitude')
                        ), row.names = FALSE)
    ))
    message('DONE! Total count of records so far: ', dim(shops)[1])
}
unlink(tmp)

message('Giving structure to dataset...')
shops <- data.table(cbind.data.frame(
            lapply(shops, 
                   function(x) 
                        unlist(lapply(x, 
                                      function(y) 
                                          ifelse(is.null(unlist(y)), NA, y) 
                        )) 
            ), 
            stringsAsFactors = FALSE 
         ))

message('Checking missing values by variable...')
sapply(names(shops), function(x) shops[is.na(get(x)), .N])

message('Cleaning and recoding postcodes to 7-chars form...')
shops[, postcode := gsub(' ', '', postcode)]
shops[!grepl("[[:digit:]][[:alpha:]][[:alpha:]]$", postcode), postcode := NA]
shops[nchar(postcode) < 5 | nchar(postcode) > 7, postcode := NA]
shops[nchar(postcode) == 5, postcode := paste0(substr(postcode, 1, 2), '  ', substring(postcode, 3))]
shops[nchar(postcode) == 6, postcode := paste(substr(postcode, 1, 3), substring(postcode, 4))]

message('Recoding text ratings as numeric...')
shops[, rating := tolower(gsub(' ', '', rating))]
shops[rating == 'awaitinginspection', rating := '7']
shops[rating == 'awaitingpublication', rating := '8']
shops[rating == 'exempt', rating := '9']
shops[rating == 'passandeatsafe', rating := '13']
shops[rating == 'pass', rating := '12']
shops[rating == 'improvementrequired', rating := '11']

message('Casting "updated_at" as "Date" and "rating" as "numeric"...')
shops[, `:=`( updated_at = as.Date(updated_at), rating = as.numeric(rating) )]

# open connection to database
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'uk_food_hygiene_ratings')

# prepare table for sectors
setkey(shops, sector_id)
dts <- shops[, .N, .(sector_id, name = sector, rating = rating)][order(sector_id, rating)]
dts <- dcast.data.table(dts, sector_id + name ~ paste0('R', ifelse(rating < 10, '0', ''), rating), fill = 0)
dts <- dts[shops[, .(tot_shops = .N), sector_id]]

# save sectors to database and csv file for github
dbSendQuery(dbc, "TRUNCATE TABLE sectors")
dbWriteTable(dbc, 'sectors', dts, row.names = FALSE, append = TRUE)
write.csv(dts, 'data/sectors.csv', row.names = FALSE)

# prepare ratings for lads
lads[, url := NULL]
setkey(shops, lad_id)
dts <- shops[, .N, .(lad_id, rating)][order(lad_id, rating)]
dts <- dcast.data.table(dts, lad_id ~ paste0('R', ifelse(rating < 10, '0', ''), rating), fill = 0)
lads <- dts[lads, on = 'lad_id']

# save lads to database and csv file for github
dbSendQuery(dbc, "TRUNCATE TABLE lads")
dbWriteTable(dbc, 'lads', lads, row.names = FALSE, append = TRUE)
write.csv(lads, 'data/LADs.csv', row.names = FALSE)

# add OA id to shops
dbcp = dbConnect(MySQL(), group = 'dataOps', dbname = 'geography_uk')
pc <- data.table(dbGetQuery(dbcp, "SELECT postcode, OA FROM postcodes"))
dbDisconnect(dbcp)
shops <- pc[shops, on = 'postcode']

# save shops to database
shops[, sector := NULL]
dbSendQuery(dbc, "TRUNCATE TABLE shops")
dbWriteTable(dbc, 'shops', shops, row.names = FALSE, append = TRUE)

# close connection to database
dbDisconnect(dbc)

# Cut shops dataset, recode resulting subset, and save it as 'fst' for quick reading in Shiny apps


# convert to numeric
cols <- cols[!( cols %in% c('shop_ladid', 'name', 'sector', 'postcode'))]
shops[, (cols) := lapply(.SD, as.numeric), .SDcols = cols]

# Clean & Exit
rm(list = ls())
gc()
    
