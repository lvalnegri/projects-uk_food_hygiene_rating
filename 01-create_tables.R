library(RMySQL)
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'uk_food_hygiene_ratings')

### lads ------------------------------------------------------------------------------------------------------------------------
strSQL = "
    CREATE TABLE lads (
    	lad_id SMALLINT(3) NOT NULL,
    	name CHAR(50) NOT NULL COLLATE 'utf8_unicode_ci',
    	tot_shops SMALLINT(4) NOT NULL,
    	updated_at DATE NOT NULL,
    	PRIMARY KEY (lad_id)
    ) COLLATE='utf8_unicode_ci' ENGINE=MyISAM ROW_FORMAT=FIXED;
"
dbSendQuery(dbc, strSQL)

### lads_ons --------------------------------------------------------------------------------------------------------------------
strSQL = "
    CREATE TABLE lads_ons (
    	lad_id SMALLINT(3) NOT NULL,
    	lad_ons CHAR(9) NOT NULL COLLATE 'utf8_unicode_ci',
    	PRIMARY KEY (lad_id),
    	UNIQUE INDEX (lad_ons)
    ) COLLATE='utf8_unicode_ci' ENGINE=MyISAM ROW_FORMAT=FIXED;
"
dbSendQuery(dbc, strSQL)

### shops -----------------------------------------------------------------------------------------------------------------------
strSQL = "
    CREATE TABLE shops (
    	shop_id MEDIUMINT(7) UNSIGNED NOT NULL,
    	shop_ladid CHAR(25) NOT NULL COLLATE 'utf8_unicode_ci',
    	name VARCHAR(100) NOT NULL COLLATE 'utf8_unicode_ci',
    	postcode CHAR(7) NULL DEFAULT NULL COLLATE 'utf8_unicode_ci',
    	lad_id SMALLINT(3) UNSIGNED NOT NULL,
    	OA CHAR(9) NULL DEFAULT NULL COLLATE 'utf8_unicode_ci',
    	x_lon DECIMAL(9,7) NULL DEFAULT NULL,
    	y_lat DECIMAL(9,7) UNSIGNED NULL DEFAULT NULL,
    	sector_id SMALLINT(5) UNSIGNED NOT NULL,
    	rating TINYINT(1) UNSIGNED NULL DEFAULT NULL,
    	score_H TINYINT(3) UNSIGNED NULL DEFAULT NULL,
    	score_S TINYINT(3) UNSIGNED NULL DEFAULT NULL,
    	score_C TINYINT(3) UNSIGNED NULL DEFAULT NULL,
    	updated_at INT(8) UNSIGNED NULL DEFAULT NULL,
    	PRIMARY KEY (shop_id),
    	INDEX (postcode),
    	INDEX (rating),
    	INDEX (sector_id),
    	INDEX (lad_id),
    	INDEX (OA)
    ) COLLATE='utf8_unicode_ci' ENGINE=MyISAM ROW_FORMAT=FIXED;
"
dbSendQuery(dbc, strSQL)

### sectors ----------------------------------------------------------------------------------------------------------------------
strSQL = "
    CREATE TABLE sectors (
    	sector_id SMALLINT(4) UNSIGNED NOT NULL,
    	name VARCHAR(50) NOT NULL COLLATE 'utf8_unicode_ci',
    	PRIMARY KEY (sector_id)
    ) COLLATE='utf8_unicode_ci' ENGINE=MyISAM ROW_FORMAT=FIXED;
"
dbSendQuery(dbc, strSQL)

### scores ----------------------------------------------------------------------------------------------------------------------
strSQL = "
    CREATE TABLE scores (
    	category CHAR(1) NOT NULL COMMENT 'H- Hygiene, S- Structural, C- Confidence In Management' COLLATE 'utf8_unicode_ci',
    	score TINYINT(2) UNSIGNED NOT NULL,
    	description CHAR(50) NOT NULL COLLATE 'utf8_unicode_ci',
    	PRIMARY KEY (category, score)
    ) COLLATE='utf8_unicode_ci' ENGINE=MyISAM ROW_FORMAT=FIXED;
"
dbSendQuery(dbc, strSQL)


### Clean & Exit ----------------------------------------------------------------------------------------------------------------
dbDisconnect(dbc)
rm(list = ls())
gc()


