#!/bin/bash

/etc/init.d/mediatomb stop
mysql -u root -p -e "use mediatomb; drop table mt_autoscan; drop table mt_cds_active_item; drop table mt_cds_object; drop table mt_internal_setting;"
/etc/init.d/mediatomb start
