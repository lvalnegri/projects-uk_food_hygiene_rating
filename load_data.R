# source data main page: http://ratings.food.gov.uk/open-data
# example URL for LAD XXX: http://ratings.food.gov.uk/OpenDataFiles/FHRSXXXen-GB.xml

lapply(c('data.table', 'RMySQL', 'rvest', 'xml2'), require, character.only = TRUE)

dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'uk_food_hygiene_ratings')

lads <- read_html('http://ratings.food.gov.uk/open-data') %>%
            html_nodes('#openDataStatic a') %>%
            html_attr('href') %>%
            as.data.frame() %>%
            sort()
names(lads) <- 'lad_id'
lads <- subset(lads, !grepl('cy', lad_id)) 
lads$lad_id <- substr(lads$lad_id, 46, 48)


bizTypeIDs <- data.frame(V0 = character(0), V1 = numeric(0))
geoCoord <- data.frame(V1 = character(0), V2 = numeric(0), V3 = numeric(0))

print(paste('Processing local authorities'))
for(idx in 1:nrow(lads)){
    print(paste('Processing file n. ', idx,' out of ',nrow(lads) ) )
    xml.url <- paste0('http://ratings.food.gov.uk/OpenDataFiles/FHRS', lads[idx], 'en-GB.xml')
    xmlfile <- xmlToList(xmlTreeParse(xml.url))[[2]]
    print(paste('Updating count of shops:', length(xmlfile)))
    dbSendQuery(db_conn, paste('UPDATE lads SET shops =', length(xmlfile), 'WHERE fla_id =', lads[idx]) )

    geoCoord <- rbind(geoCoord,
                        as.data.frame(cbind(
                            lapply(xmlfile, '[[', 'FHRSID'), 
                            lapply(lapply(xmlfile, '[[', 'Geocode'), '[[', 'Longitude'),
                            lapply(lapply(xmlfile, '[[', 'Geocode'), '[[', 'Latitude')
                        ), row.names = FALSE)
    )
    
    
        
    bizTypeIDs <- rbind(bizTypeIDs, 
                        unique(as.data.frame(cbind(
                            lapply(xmlfile, '[[', 'BusinessType'), 
                            lapply(xmlfile, '[[', 'BusinessTypeID')
                        ), row.names = FALSE))
    )
    bizTypeIDs <- unique(bizTypeIDs)
    xmlfile$EstablishmentDetail$BusinessType <- NULL
    
    # print(paste('Appending records'))
    # if(idx == 1){
    #     dataset <- unique(as.data.frame(cbind(lapply(xmlfile, "[[", 4), lapply(xmlfile, "[[", 5)), row.names = FALSE))
    # } else {
    #     dataset <- append(dataset, xmlfile)
    # }
    # print(paste('Total count of records so far', length(dataset)))
}


# Clean & Exit
rm(list = ls())
gc()

