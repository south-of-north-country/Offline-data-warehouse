#!/bin/bash

hive_db_name=gmall
mysql_db_name=gmall_report

export_data() {
/opt/module/sqoop/bin/sqoop export \
--connect "jdbc:mysql://hadoop102:3306/${mysql_db_name}?useUnicode=true&characterEncoding=utf-8"  \
--username root \
--password 000000 \
--table $1 \
--num-mappers 1 \
--export-dir /warehouse/$hive_db_name/ads/$1 \
--input-fields-terminated-by "\t" \
--update-mode allowinsert \
--update-key $2 \
--input-null-string '\\N'    \
--input-null-non-string '\\N'
}

case $1 in
  "ads_activity_stats" )
    export_data "ads_activity_stats" "dt,activity_id"
  ;;

  "ads_coupon_stats" )
    export_data "ads_coupon_stats" "dt,coupon_id"
  ;;

  "ads_order_by_province" )
    export_data "ads_order_by_province" "dt,recent_days,province_id"
  ;;

  "ads_order_spu_stats" )
    export_data "ads_order_spu_stats" "dt,recent_days,spu_id"
  ;;

  "ads_order_total" )
    export_data "ads_order_total" "dt,recent_days"
  ;;

  "ads_page_path" )
    export_data "ads_page_path" "dt,recent_days,source,target"
  ;;

  "ads_repeat_purchase" )
    export_data "ads_repeat_purchase" "dt,recent_days,tm_id"
  ;;

  "ads_user_action" )
    export_data "ads_user_action" "dt,recent_days"
  ;;

  "ads_user_change" )
    export_data "ads_user_change" "dt"
  ;;

  "ads_user_retention" )
    export_data "ads_user_retention" "create_date,retention_day"
  ;;

  "ads_user_total" )
    export_data "ads_user_total" "dt,recent_days"
  ;;

  "ads_visit_stats" )
    export_data "ads_visit_stats" "dt,recent_days,is_new,channel"
  ;;
  "all" )
    export_data "ads_activity_stats" "dt,activity_id"
    export_data "ads_coupon_stats" "dt,coupon_id"
    export_data "ads_order_by_province" "dt,recent_days,province_id"
    export_data "ads_order_spu_stats" "dt,recent_days,spu_id"
    export_data "ads_order_total" "dt,recent_days"
    export_data "ads_page_path" "dt,recent_days,source,target"
    export_data "ads_repeat_purchase" "dt,recent_days,tm_id"
    export_data "ads_user_action" "dt,recent_days"
    export_data "ads_user_change" "dt"
    export_data "ads_user_retention" "create_date,retention_day"
    export_data "ads_user_total" "dt,recent_days"
    export_data "ads_visit_stats" "dt,recent_days,is_new,channel"
  ;;
esac

