# source data main page: http://ratings.food.gov.uk/open-data
# example URL for LAD: http://ratings.food.gov.uk/OpenDataFiles/FHRS528en-GB.xml

lapply(c('data.table', 'RMySQL', 'xml2'), require, character.only = TRUE)

dbc = dbConnect(MySQL(), group = 'homeserver', dbname = 'food_hygiene_ratings')

# print(paste('Processing scores descriptions...'))
# scores <- unlist(t(xmlToList(xmlTreeParse('http://ratings.food.gov.uk/open-data-resources/lookupData/ScoreDescriptors.xml'))[[3]]))
# scores <- scores[(length(scores)/6*2+1):length(scores)]
# scores <- as.data.frame(matrix(scores, ncol = 4, byrow = FALSE)) 
# names(scores) <- c('description', 'id', 'value', 'category')
# dbWriteTable(db_conn, 'scores', scores, rownames = FALSE, append = TRUE)
# print(paste('DONE!'))


bizTypeIDs <- data.frame(V0 = character(0), V1 = numeric(0))
geoCoord <- data.frame(V1 = character(0), V2 = numeric(0), V3 = numeric(0))

print(paste('Processing local authorities'))
LAD <- dbReadTable(db_conn, 'LAD')
for(idx in 1:nrow(LAD)){
    print(paste('Processing file n. ', idx,' out of ',nrow(LAD), '. Local authority: ', LAD[idx, 2], ' - ', LAD[idx, 3], '.', sep = '') )
    xml.url <- paste('http://ratings.food.gov.uk/OpenDataFiles/FHRS', ifelse(LAD[idx, 2] < 100, '0', ''), LAD[idx, 2], 'en-GB.xml', sep = '')
    xmlfile <- xmlToList(xmlTreeParse(xml.url))[[2]]
    print(paste('Updating count of shops:', length(xmlfile)))
    dbSendQuery(db_conn, paste('UPDATE LAD SET shops =', length(xmlfile), 'WHERE FLA_ID =', LAD[idx, 2]) )

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

