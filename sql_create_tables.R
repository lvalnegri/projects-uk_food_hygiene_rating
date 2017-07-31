library(RMySQL)
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'uk_food_hygiene_ratings')

### ratings --------------------------------------------------------------------------------------------------------
strSQL = "
    CREATE TABLE rtings (

    ) COLLATE='utf8_unicode_ci' ENGINE=MyISAM ROW_FORMAT=FIXED;
"
dbSendQuery(dbc, strSQL)

### scores --------------------------------------------------------------------------------------------------------
strSQL = "
    CREATE TABLE scores (

    ) COLLATE='utf8_unicode_ci' ENGINE=MyISAM ROW_FORMAT=FIXED;
"
dbSendQuery(dbc, strSQL)

###  --------------------------------------------------------------------------------------------------------
strSQL = "
    CREATE TABLE LAD (

    ) COLLATE='utf8_unicode_ci' ENGINE=MyISAM ROW_FORMAT=FIXED;
"
dbSendQuery(dbc, strSQL)


# Clean & Exit
dbDisconnect(dbc)
rm(list = ls())
gc()


