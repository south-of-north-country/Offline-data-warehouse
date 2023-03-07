#!/bin/bash

APP=gmall

if [ -n "$2" ] ;then
   do_date=$2
else 
   echo "请传入日期参数"
   exit
fi 

dwt_visitor_topic="
insert overwrite table ${APP}.dwt_visitor_topic partition(dt='$do_date')
select
    nvl(1d_ago.mid_id,old.mid_id),
    nvl(1d_ago.brand,old.brand),
    nvl(1d_ago.model,old.model),
    nvl(1d_ago.channel,old.channel),
    nvl(1d_ago.os,old.os),
    nvl(1d_ago.area_code,old.area_code),
    nvl(1d_ago.version_code,old.version_code),
    case when old.mid_id is null and 1d_ago.is_new=1 then '$do_date'
         when old.mid_id is null and 1d_ago.is_new=0 then '2020-06-13'--无法获取准确的首次登录日期，给定一个数仓搭建日之前的日期
         else old.visit_date_first end,
    if(1d_ago.mid_id is not null,'$do_date',old.visit_date_last),
    nvl(1d_ago.visit_count,0),
    if(1d_ago.mid_id is null,0,1),
    nvl(old.visit_last_7d_count,0)+nvl(1d_ago.visit_count,0)- nvl(7d_ago.visit_count,0),
    nvl(old.visit_last_7d_day_count,0)+if(1d_ago.mid_id is null,0,1)- if(7d_ago.mid_id is null,0,1),
    nvl(old.visit_last_30d_count,0)+nvl(1d_ago.visit_count,0)- nvl(30d_ago.visit_count,0),
    nvl(old.visit_last_30d_day_count,0)+if(1d_ago.mid_id is null,0,1)- if(30d_ago.mid_id is null,0,1),
    nvl(old.visit_count,0)+nvl(1d_ago.visit_count,0),
    nvl(old.visit_day_count,0)+if(1d_ago.mid_id is null,0,1)
from
(
    select
        mid_id,
        brand,
        model,
        channel,
        os,
        area_code,
        version_code,
        visit_date_first,
        visit_date_last,
        visit_last_1d_count,
        visit_last_1d_day_count,
        visit_last_7d_count,
        visit_last_7d_day_count,
        visit_last_30d_count,
        visit_last_30d_day_count,
        visit_count,
        visit_day_count
    from ${APP}.dwt_visitor_topic
    where dt=date_add('$do_date',-1)
)old
full outer join
(
    select
        mid_id,
        brand,
        model,
        is_new,
        channel,
        os,
        area_code,
        version_code,
        visit_count
    from ${APP}.dws_visitor_action_daycount
    where dt='$do_date'
)1d_ago
on old.mid_id=1d_ago.mid_id
left join
(
    select
        mid_id,
        brand,
        model,
        is_new,
        channel,
        os,
        area_code,
        version_code,
        visit_count
    from ${APP}.dws_visitor_action_daycount
    where dt=date_add('$do_date',-7)
)7d_ago
on old.mid_id=7d_ago.mid_id
left join
(
    select
        mid_id,
        brand,
        model,
        is_new,
        channel,
        os,
        area_code,
        version_code,
        visit_count
    from ${APP}.dws_visitor_action_daycount
    where dt=date_add('$do_date',-30)
)30d_ago
on old.mid_id=30d_ago.mid_id;
"

dwt_user_topic="
insert overwrite table ${APP}.dwt_user_topic partition(dt='$do_date')
select
    id,
    login_date_first,--以用户的创建日期作为首次登录日期
    nvl(login_date_last,date_add('$do_date',-1)),--若有历史登录记录，则根据历史记录获取末次登录日期，否则统一指定一个日期
    nvl(login_last_1d_count,0),
    nvl(login_last_1d_day_count,0),
    nvl(login_last_7d_count,0),
    nvl(login_last_7d_day_count,0),
    nvl(login_last_30d_count,0),
    nvl(login_last_30d_day_count,0),
    nvl(login_count,0),
    nvl(login_day_count,0),
    order_date_first,
    order_date_last,
    nvl(order_last_1d_count,0),
    nvl(order_activity_last_1d_count,0),
    nvl(order_activity_reduce_last_1d_amount,0),
    nvl(order_coupon_last_1d_count,0),
    nvl(order_coupon_reduce_last_1d_amount,0),
    nvl(order_last_1d_original_amount,0),
    nvl(order_last_1d_final_amount,0),
    nvl(order_last_7d_count,0),
    nvl(order_activity_last_7d_count,0),
    nvl(order_activity_reduce_last_7d_amount,0),
    nvl(order_coupon_last_7d_count,0),
    nvl(order_coupon_reduce_last_7d_amount,0),
    nvl(order_last_7d_original_amount,0),
    nvl(order_last_7d_final_amount,0),
    nvl(order_last_30d_count,0),
    nvl(order_activity_last_30d_count,0),
    nvl(order_activity_reduce_last_30d_amount,0),
    nvl(order_coupon_last_30d_count,0),
    nvl(order_coupon_reduce_last_30d_amount,0),
    nvl(order_last_30d_original_amount,0),
    nvl(order_last_30d_final_amount,0),
    nvl(order_count,0),
    nvl(order_activity_count,0),
    nvl(order_activity_reduce_amount,0),
    nvl(order_coupon_count,0),
    nvl(order_coupon_reduce_amount,0),
    nvl(order_original_amount,0),
    nvl(order_final_amount,0),
    payment_date_first,
    payment_date_last,
    nvl(payment_last_1d_count,0),
    nvl(payment_last_1d_amount,0),
    nvl(payment_last_7d_count,0),
    nvl(payment_last_7d_amount,0),
    nvl(payment_last_30d_count,0),
    nvl(payment_last_30d_amount,0),
    nvl(payment_count,0),
    nvl(payment_amount,0),
    nvl(refund_order_last_1d_count,0),
    nvl(refund_order_last_1d_num,0),
    nvl(refund_order_last_1d_amount,0),
    nvl(refund_order_last_7d_count,0),
    nvl(refund_order_last_7d_num,0),
    nvl(refund_order_last_7d_amount,0),
    nvl(refund_order_last_30d_count,0),
    nvl(refund_order_last_30d_num,0),
    nvl(refund_order_last_30d_amount,0),
    nvl(refund_order_count,0),
    nvl(refund_order_num,0),
    nvl(refund_order_amount,0),
    nvl(refund_payment_last_1d_count,0),
    nvl(refund_payment_last_1d_num,0),
    nvl(refund_payment_last_1d_amount,0),
    nvl(refund_payment_last_7d_count,0),
    nvl(refund_payment_last_7d_num,0),
    nvl(refund_payment_last_7d_amount,0),
    nvl(refund_payment_last_30d_count,0),
    nvl(refund_payment_last_30d_num,0),
    nvl(refund_payment_last_30d_amount,0),
    nvl(refund_payment_count,0),
    nvl(refund_payment_num,0),
    nvl(refund_payment_amount,0),
    nvl(cart_last_1d_count,0),
    nvl(cart_last_7d_count,0),
    nvl(cart_last_30d_count,0),
    nvl(cart_count,0),
    nvl(favor_last_1d_count,0),
    nvl(favor_last_7d_count,0),
    nvl(favor_last_30d_count,0),
    nvl(favor_count,0),
    nvl(coupon_last_1d_get_count,0),
    nvl(coupon_last_1d_using_count,0),
    nvl(coupon_last_1d_used_count,0),
    nvl(coupon_last_7d_get_count,0),
    nvl(coupon_last_7d_using_count,0),
    nvl(coupon_last_7d_used_count,0),
    nvl(coupon_last_30d_get_count,0),
    nvl(coupon_last_30d_using_count,0),
    nvl(coupon_last_30d_used_count,0),
    nvl(coupon_get_count,0),
    nvl(coupon_using_count,0),
    nvl(coupon_used_count,0),
    nvl(appraise_last_1d_good_count,0),
    nvl(appraise_last_1d_mid_count,0),
    nvl(appraise_last_1d_bad_count,0),
    nvl(appraise_last_1d_default_count,0),
    nvl(appraise_last_7d_good_count,0),
    nvl(appraise_last_7d_mid_count,0),
    nvl(appraise_last_7d_bad_count,0),
    nvl(appraise_last_7d_default_count,0),
    nvl(appraise_last_30d_good_count,0),
    nvl(appraise_last_30d_mid_count,0),
    nvl(appraise_last_30d_bad_count,0),
    nvl(appraise_last_30d_default_count,0),
    nvl(appraise_good_count,0),
    nvl(appraise_mid_count,0),
    nvl(appraise_bad_count,0),
    nvl(appraise_default_count,0)
from
(
    select
        id,
        date_format(create_time,'yyyy-MM-dd') login_date_first
    from ${APP}.dim_user_info
    where dt='9999-99-99'
)t1
left join
(
    select
        user_id user_id,
        max(dt) login_date_last,
        sum(if(dt='$do_date',login_count,0)) login_last_1d_count,
        sum(if(dt='$do_date' and login_count>0,1,0)) login_last_1d_day_count,
        sum(if(dt>=date_add('$do_date',-6),login_count,0)) login_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6) and login_count>0,1,0)) login_last_7d_day_count,
        sum(if(dt>=date_add('$do_date',-29),login_count,0)) login_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29) and login_count>0,1,0)) login_last_30d_day_count,
        sum(login_count) login_count,
        sum(if(login_count>0,1,0)) login_day_count,
        min(if(order_count>0,dt,null)) order_date_first,
        max(if(order_count>0,dt,null)) order_date_last,
        sum(if(dt='$do_date',order_count,0)) order_last_1d_count,
        sum(if(dt='$do_date',order_activity_count,0)) order_activity_last_1d_count,
        sum(if(dt='$do_date',order_activity_reduce_amount,0)) order_activity_reduce_last_1d_amount,
        sum(if(dt='$do_date',order_coupon_count,0)) order_coupon_last_1d_count,
        sum(if(dt='$do_date',order_coupon_reduce_amount,0)) order_coupon_reduce_last_1d_amount,
        sum(if(dt='$do_date',order_original_amount,0)) order_last_1d_original_amount,
        sum(if(dt='$do_date',order_final_amount,0)) order_last_1d_final_amount,
        sum(if(dt>=date_add('$do_date',-6),order_count,0)) order_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),order_activity_count,0)) order_activity_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),order_activity_reduce_amount,0)) order_activity_reduce_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-6),order_coupon_count,0)) order_coupon_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),order_coupon_reduce_amount,0)) order_coupon_reduce_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-6),order_original_amount,0)) order_last_7d_original_amount,
        sum(if(dt>=date_add('$do_date',-6),order_final_amount,0)) order_last_7d_final_amount,
        sum(if(dt>=date_add('$do_date',-29),order_count,0)) order_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),order_activity_count,0)) order_activity_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),order_activity_reduce_amount,0)) order_activity_reduce_last_30d_amount,
        sum(if(dt>=date_add('$do_date',-29),order_coupon_count,0)) order_coupon_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),order_coupon_reduce_amount,0)) order_coupon_reduce_last_30d_amount,
        sum(if(dt>=date_add('$do_date',-29),order_original_amount,0)) order_last_30d_original_amount,
        sum(if(dt>=date_add('$do_date',-29),order_final_amount,0)) order_last_30d_final_amount,
        sum(order_count) order_count,
        sum(order_activity_count) order_activity_count,
        sum(order_activity_reduce_amount) order_activity_reduce_amount,
        sum(order_coupon_count) order_coupon_count,
        sum(order_coupon_reduce_amount) order_coupon_reduce_amount,
        sum(order_original_amount) order_original_amount,
        sum(order_final_amount) order_final_amount,
        min(if(payment_count>0,dt,null)) payment_date_first,
        max(if(payment_count>0,dt,null)) payment_date_last,
        sum(if(dt='$do_date',payment_count,0)) payment_last_1d_count,
        sum(if(dt='$do_date',payment_amount,0)) payment_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),payment_count,0)) payment_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),payment_amount,0)) payment_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),payment_count,0)) payment_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),payment_amount,0)) payment_last_30d_amount,
        sum(payment_count) payment_count,
        sum(payment_amount) payment_amount,
        sum(if(dt='$do_date',refund_order_count,0)) refund_order_last_1d_count,
        sum(if(dt='$do_date',refund_order_num,0)) refund_order_last_1d_num,
        sum(if(dt='$do_date',refund_order_amount,0)) refund_order_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),refund_order_count,0)) refund_order_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),refund_order_num,0)) refund_order_last_7d_num,
        sum(if(dt>=date_add('$do_date',-6),refund_order_amount,0)) refund_order_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),refund_order_count,0)) refund_order_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),refund_order_num,0)) refund_order_last_30d_num,
        sum(if(dt>=date_add('$do_date',-29),refund_order_amount,0)) refund_order_last_30d_amount,
        sum(refund_order_count) refund_order_count,
        sum(refund_order_num) refund_order_num,
        sum(refund_order_amount) refund_order_amount,
        sum(if(dt='$do_date',refund_payment_count,0)) refund_payment_last_1d_count,
        sum(if(dt='$do_date',refund_payment_num,0)) refund_payment_last_1d_num,
        sum(if(dt='$do_date',refund_payment_amount,0)) refund_payment_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),refund_payment_count,0)) refund_payment_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),refund_payment_num,0)) refund_payment_last_7d_num,
        sum(if(dt>=date_add('$do_date',-6),refund_payment_amount,0)) refund_payment_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),refund_payment_count,0)) refund_payment_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),refund_payment_num,0)) refund_payment_last_30d_num,
        sum(if(dt>=date_add('$do_date',-29),refund_payment_amount,0)) refund_payment_last_30d_amount,
        sum(refund_payment_count) refund_payment_count,
        sum(refund_payment_num) refund_payment_num,
        sum(refund_payment_amount) refund_payment_amount,
        sum(if(dt='$do_date',cart_count,0)) cart_last_1d_count,
        sum(if(dt>=date_add('$do_date',-6),cart_count,0)) cart_last_7d_count,
        sum(if(dt>=date_add('$do_date',-29),cart_count,0)) cart_last_30d_count,
        sum(cart_count) cart_count,
        sum(if(dt='$do_date',favor_count,0)) favor_last_1d_count,
        sum(if(dt>=date_add('$do_date',-6),favor_count,0)) favor_last_7d_count,
        sum(if(dt>=date_add('$do_date',-29),favor_count,0)) favor_last_30d_count,
        sum(favor_count) favor_count,
        sum(if(dt='$do_date',coupon_get_count,0)) coupon_last_1d_get_count,
        sum(if(dt='$do_date',coupon_using_count,0)) coupon_last_1d_using_count,
        sum(if(dt='$do_date',coupon_used_count,0)) coupon_last_1d_used_count,
        sum(if(dt>=date_add('$do_date',-6),coupon_get_count,0)) coupon_last_7d_get_count,
        sum(if(dt>=date_add('$do_date',-6),coupon_using_count,0)) coupon_last_7d_using_count,
        sum(if(dt>=date_add('$do_date',-6),coupon_used_count,0)) coupon_last_7d_used_count,
        sum(if(dt>=date_add('$do_date',-29),coupon_get_count,0)) coupon_last_30d_get_count,
        sum(if(dt>=date_add('$do_date',-29),coupon_using_count,0)) coupon_last_30d_using_count,
        sum(if(dt>=date_add('$do_date',-29),coupon_used_count,0)) coupon_last_30d_used_count,
        sum(coupon_get_count) coupon_get_count,
        sum(coupon_using_count) coupon_using_count,
        sum(coupon_used_count) coupon_used_count,
        sum(if(dt='$do_date',appraise_good_count,0)) appraise_last_1d_good_count,
        sum(if(dt='$do_date',appraise_mid_count,0)) appraise_last_1d_mid_count,
        sum(if(dt='$do_date',appraise_bad_count,0)) appraise_last_1d_bad_count,
        sum(if(dt='$do_date',appraise_default_count,0)) appraise_last_1d_default_count,
        sum(if(dt>=date_add('$do_date',-6),appraise_good_count,0)) appraise_last_7d_good_count,
        sum(if(dt>=date_add('$do_date',-6),appraise_mid_count,0)) appraise_last_7d_mid_count,
        sum(if(dt>=date_add('$do_date',-6),appraise_bad_count,0)) appraise_last_7d_bad_count,
        sum(if(dt>=date_add('$do_date',-6),appraise_default_count,0)) appraise_last_7d_default_count,
        sum(if(dt>=date_add('$do_date',-29),appraise_good_count,0)) appraise_last_30d_good_count,
        sum(if(dt>=date_add('$do_date',-29),appraise_mid_count,0)) appraise_last_30d_mid_count,
        sum(if(dt>=date_add('$do_date',-29),appraise_bad_count,0)) appraise_last_30d_bad_count,
        sum(if(dt>=date_add('$do_date',-29),appraise_default_count,0)) appraise_last_30d_default_count,
        sum(appraise_good_count) appraise_good_count,
        sum(appraise_mid_count) appraise_mid_count,
        sum(appraise_bad_count) appraise_bad_count,
        sum(appraise_default_count) appraise_default_count
    from ${APP}.dws_user_action_daycount
    group by user_id
)t2
on t1.id=t2.user_id;
"

dwt_sku_topic="
insert overwrite table ${APP}.dwt_sku_topic partition(dt='$do_date')
select
    id,
    nvl(order_last_1d_count,0),
    nvl(order_last_1d_num,0),
    nvl(order_activity_last_1d_count,0),
    nvl(order_coupon_last_1d_count,0),
    nvl(order_activity_reduce_last_1d_amount,0),
    nvl(order_coupon_reduce_last_1d_amount,0),
    nvl(order_last_1d_original_amount,0),
    nvl(order_last_1d_final_amount,0),
    nvl(order_last_7d_count,0),
    nvl(order_last_7d_num,0),
    nvl(order_activity_last_7d_count,0),
    nvl(order_coupon_last_7d_count,0),
    nvl(order_activity_reduce_last_7d_amount,0),
    nvl(order_coupon_reduce_last_7d_amount,0),
    nvl(order_last_7d_original_amount,0),
    nvl(order_last_7d_final_amount,0),
    nvl(order_last_30d_count,0),
    nvl(order_last_30d_num,0),
    nvl(order_activity_last_30d_count,0),
    nvl(order_coupon_last_30d_count,0),
    nvl(order_activity_reduce_last_30d_amount,0),
    nvl(order_coupon_reduce_last_30d_amount,0),
    nvl(order_last_30d_original_amount,0),
    nvl(order_last_30d_final_amount,0),
    nvl(order_count,0),
    nvl(order_num,0),
    nvl(order_activity_count,0),
    nvl(order_coupon_count,0),
    nvl(order_activity_reduce_amount,0),
    nvl(order_coupon_reduce_amount,0),
    nvl(order_original_amount,0),
    nvl(order_final_amount,0),
    nvl(payment_last_1d_count,0),
    nvl(payment_last_1d_num,0),
    nvl(payment_last_1d_amount,0),
    nvl(payment_last_7d_count,0),
    nvl(payment_last_7d_num,0),
    nvl(payment_last_7d_amount,0),
    nvl(payment_last_30d_count,0),
    nvl(payment_last_30d_num,0),
    nvl(payment_last_30d_amount,0),
    nvl(payment_count,0),
    nvl(payment_num,0),
    nvl(payment_amount,0),
    nvl(refund_order_last_1d_count,0),
    nvl(refund_order_last_1d_num,0),
    nvl(refund_order_last_1d_amount,0),
    nvl(refund_order_last_7d_count,0),
    nvl(refund_order_last_7d_num,0),
    nvl(refund_order_last_7d_amount,0),
    nvl(refund_order_last_30d_count,0),
    nvl(refund_order_last_30d_num,0),
    nvl(refund_order_last_30d_amount,0),
    nvl(refund_order_count,0),
    nvl(refund_order_num,0),
    nvl(refund_order_amount,0),
    nvl(refund_payment_last_1d_count,0),
    nvl(refund_payment_last_1d_num,0),
    nvl(refund_payment_last_1d_amount,0),
    nvl(refund_payment_last_7d_count,0),
    nvl(refund_payment_last_7d_num,0),
    nvl(refund_payment_last_7d_amount,0),
    nvl(refund_payment_last_30d_count,0),
    nvl(refund_payment_last_30d_num,0),
    nvl(refund_payment_last_30d_amount,0),
    nvl(refund_payment_count,0),
    nvl(refund_payment_num,0),
    nvl(refund_payment_amount,0),
    nvl(cart_last_1d_count,0),
    nvl(cart_last_7d_count,0),
    nvl(cart_last_30d_count,0),
    nvl(cart_count,0),
    nvl(favor_last_1d_count,0),
    nvl(favor_last_7d_count,0),
    nvl(favor_last_30d_count,0),
    nvl(favor_count,0),
    nvl(appraise_last_1d_good_count,0),
    nvl(appraise_last_1d_mid_count,0),
    nvl(appraise_last_1d_bad_count,0),
    nvl(appraise_last_1d_default_count,0),
    nvl(appraise_last_7d_good_count,0),
    nvl(appraise_last_7d_mid_count,0),
    nvl(appraise_last_7d_bad_count,0),
    nvl(appraise_last_7d_default_count,0),
    nvl(appraise_last_30d_good_count,0),
    nvl(appraise_last_30d_mid_count,0),
    nvl(appraise_last_30d_bad_count,0),
    nvl(appraise_last_30d_default_count,0),
    nvl(appraise_good_count,0),
    nvl(appraise_mid_count,0),
    nvl(appraise_bad_count,0),
    nvl(appraise_default_count,0)
from
(
    select
        id
    from ${APP}.dim_sku_info
    where dt='$do_date'
)t1
left join
(
    select
        sku_id,
        sum(if(dt='$do_date',order_count,0)) order_last_1d_count,
        sum(if(dt='$do_date',order_num,0)) order_last_1d_num,
        sum(if(dt='$do_date',order_activity_count,0)) order_activity_last_1d_count,
        sum(if(dt='$do_date',order_coupon_count,0)) order_coupon_last_1d_count,
        sum(if(dt='$do_date',order_activity_reduce_amount,0)) order_activity_reduce_last_1d_amount,
        sum(if(dt='$do_date',order_coupon_reduce_amount,0)) order_coupon_reduce_last_1d_amount,
        sum(if(dt='$do_date',order_original_amount,0)) order_last_1d_original_amount,
        sum(if(dt='$do_date',order_final_amount,0)) order_last_1d_final_amount,
        sum(if(dt>=date_add('$do_date',-6),order_count,0)) order_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),order_num,0)) order_last_7d_num,
        sum(if(dt>=date_add('$do_date',-6),order_activity_count,0)) order_activity_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),order_coupon_count,0)) order_coupon_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),order_activity_reduce_amount,0)) order_activity_reduce_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-6),order_coupon_reduce_amount,0)) order_coupon_reduce_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-6),order_original_amount,0)) order_last_7d_original_amount,
        sum(if(dt>=date_add('$do_date',-6),order_final_amount,0)) order_last_7d_final_amount,
        sum(if(dt>=date_add('$do_date',-29),order_count,0)) order_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),order_num,0)) order_last_30d_num,
        sum(if(dt>=date_add('$do_date',-29),order_activity_count,0)) order_activity_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),order_coupon_count,0)) order_coupon_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),order_activity_reduce_amount,0)) order_activity_reduce_last_30d_amount,
        sum(if(dt>=date_add('$do_date',-29),order_coupon_reduce_amount,0)) order_coupon_reduce_last_30d_amount,
        sum(if(dt>=date_add('$do_date',-29),order_original_amount,0)) order_last_30d_original_amount,
        sum(if(dt>=date_add('$do_date',-29),order_final_amount,0)) order_last_30d_final_amount,
        sum(order_count) order_count,
        sum(order_num) order_num,
        sum(order_activity_count) order_activity_count,
        sum(order_coupon_count) order_coupon_count,
        sum(order_activity_reduce_amount) order_activity_reduce_amount,
        sum(order_coupon_reduce_amount) order_coupon_reduce_amount,
        sum(order_original_amount) order_original_amount,
        sum(order_final_amount) order_final_amount,
        sum(if(dt='$do_date',payment_count,0)) payment_last_1d_count,
        sum(if(dt='$do_date',payment_num,0)) payment_last_1d_num,
        sum(if(dt='$do_date',payment_amount,0)) payment_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),payment_count,0)) payment_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),payment_num,0)) payment_last_7d_num,
        sum(if(dt>=date_add('$do_date',-6),payment_amount,0)) payment_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),payment_count,0)) payment_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),payment_num,0)) payment_last_30d_num,
        sum(if(dt>=date_add('$do_date',-29),payment_amount,0)) payment_last_30d_amount,
        sum(payment_count) payment_count,
        sum(payment_num) payment_num,
        sum(payment_amount) payment_amount,
        sum(if(dt='$do_date',refund_order_count,0)) refund_order_last_1d_count,
        sum(if(dt='$do_date',refund_order_num,0)) refund_order_last_1d_num,
        sum(if(dt='$do_date',refund_order_amount,0)) refund_order_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),refund_order_count,0)) refund_order_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),refund_order_num,0)) refund_order_last_7d_num,
        sum(if(dt>=date_add('$do_date',-6),refund_order_amount,0)) refund_order_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),refund_order_count,0)) refund_order_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),refund_order_num,0)) refund_order_last_30d_num,
        sum(if(dt>=date_add('$do_date',-29),refund_order_amount,0)) refund_order_last_30d_amount,
        sum(refund_order_count) refund_order_count,
        sum(refund_order_num) refund_order_num,
        sum(refund_order_amount) refund_order_amount,
        sum(if(dt='$do_date',refund_payment_count,0)) refund_payment_last_1d_count,
        sum(if(dt='$do_date',refund_payment_num,0)) refund_payment_last_1d_num,
        sum(if(dt='$do_date',refund_payment_amount,0)) refund_payment_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),refund_payment_count,0)) refund_payment_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),refund_payment_num,0)) refund_payment_last_7d_num,
        sum(if(dt>=date_add('$do_date',-6),refund_payment_amount,0)) refund_payment_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),refund_payment_count,0)) refund_payment_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),refund_payment_num,0)) refund_payment_last_30d_num,
        sum(if(dt>=date_add('$do_date',-29),refund_payment_amount,0)) refund_payment_last_30d_amount,
        sum(refund_payment_count) refund_payment_count,
        sum(refund_payment_num) refund_payment_num,
        sum(refund_payment_amount) refund_payment_amount,
        sum(if(dt='$do_date',cart_count,0)) cart_last_1d_count,
        sum(if(dt>=date_add('$do_date',-6),cart_count,0)) cart_last_7d_count,
        sum(if(dt>=date_add('$do_date',-29),cart_count,0)) cart_last_30d_count,
        sum(cart_count) cart_count,
        sum(if(dt='$do_date',favor_count,0)) favor_last_1d_count,
        sum(if(dt>=date_add('$do_date',-6),favor_count,0)) favor_last_7d_count,
        sum(if(dt>=date_add('$do_date',-29),favor_count,0)) favor_last_30d_count,
        sum(favor_count) favor_count,
        sum(if(dt='$do_date',appraise_good_count,0)) appraise_last_1d_good_count,
        sum(if(dt='$do_date',appraise_mid_count,0)) appraise_last_1d_mid_count,
        sum(if(dt='$do_date',appraise_bad_count,0)) appraise_last_1d_bad_count,
        sum(if(dt='$do_date',appraise_default_count,0)) appraise_last_1d_default_count,
        sum(if(dt>=date_add('$do_date',-6),appraise_good_count,0)) appraise_last_7d_good_count,
        sum(if(dt>=date_add('$do_date',-6),appraise_mid_count,0)) appraise_last_7d_mid_count,
        sum(if(dt>=date_add('$do_date',-6),appraise_bad_count,0)) appraise_last_7d_bad_count,
        sum(if(dt>=date_add('$do_date',-6),appraise_default_count,0)) appraise_last_7d_default_count,
        sum(if(dt>=date_add('$do_date',-29),appraise_good_count,0)) appraise_last_30d_good_count,
        sum(if(dt>=date_add('$do_date',-29),appraise_mid_count,0)) appraise_last_30d_mid_count,
        sum(if(dt>=date_add('$do_date',-29),appraise_bad_count,0)) appraise_last_30d_bad_count,
        sum(if(dt>=date_add('$do_date',-29),appraise_default_count,0)) appraise_last_30d_default_count,
        sum(appraise_good_count) appraise_good_count,
        sum(appraise_mid_count) appraise_mid_count,
        sum(appraise_bad_count) appraise_bad_count,
        sum(appraise_default_count) appraise_default_count
    from ${APP}.dws_sku_action_daycount
    group by sku_id
)t2
on t1.id=t2.sku_id;
"

dwt_coupon_topic="
insert overwrite table ${APP}.dwt_coupon_topic partition(dt='$do_date')
select
    id,
    nvl(get_last_1d_count,0),
    nvl(get_last_7d_count,0),
    nvl(get_last_30d_count,0),
    nvl(get_count,0),
    nvl(order_last_1d_count,0),
    nvl(order_last_1d_reduce_amount,0),
    nvl(order_last_1d_original_amount,0),
    nvl(order_last_1d_final_amount,0),
    nvl(order_last_7d_count,0),
    nvl(order_last_7d_reduce_amount,0),
    nvl(order_last_7d_original_amount,0),
    nvl(order_last_7d_final_amount,0),
    nvl(order_last_30d_count,0),
    nvl(order_last_30d_reduce_amount,0),
    nvl(order_last_30d_original_amount,0),
    nvl(order_last_30d_final_amount,0),
    nvl(order_count,0),
    nvl(order_reduce_amount,0),
    nvl(order_original_amount,0),
    nvl(order_final_amount,0),
    nvl(payment_last_1d_count,0),
    nvl(payment_last_1d_reduce_amount,0),
    nvl(payment_last_1d_amount,0),
    nvl(payment_last_7d_count,0),
    nvl(payment_last_7d_reduce_amount,0),
    nvl(payment_last_7d_amount,0),
    nvl(payment_last_30d_count,0),
    nvl(payment_last_30d_reduce_amount,0),
    nvl(payment_last_30d_amount,0),
    nvl(payment_count,0),
    nvl(payment_reduce_amount,0),
    nvl(payment_amount,0),
    nvl(expire_last_1d_count,0),
    nvl(expire_last_7d_count,0),
    nvl(expire_last_30d_count,0),
    nvl(expire_count,0)
from
(
    select
        id
    from ${APP}.dim_coupon_info
    where dt='$do_date'
)t1
left join
(
    select
        coupon_id coupon_id,
        sum(if(dt='$do_date',get_count,0)) get_last_1d_count,
        sum(if(dt>=date_add('$do_date',-6),get_count,0)) get_last_7d_count,
        sum(if(dt>=date_add('$do_date',-29),get_count,0)) get_last_30d_count,
        sum(get_count) get_count,
        sum(if(dt='$do_date',order_count,0)) order_last_1d_count,
        sum(if(dt='$do_date',order_reduce_amount,0)) order_last_1d_reduce_amount,
        sum(if(dt='$do_date',order_original_amount,0)) order_last_1d_original_amount,
        sum(if(dt='$do_date',order_final_amount,0)) order_last_1d_final_amount,
        sum(if(dt>=date_add('$do_date',-6),order_count,0)) order_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),order_reduce_amount,0)) order_last_7d_reduce_amount,
        sum(if(dt>=date_add('$do_date',-6),order_original_amount,0)) order_last_7d_original_amount,
        sum(if(dt>=date_add('$do_date',-6),order_final_amount,0)) order_last_7d_final_amount,
        sum(if(dt>=date_add('$do_date',-29),order_count,0)) order_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),order_reduce_amount,0)) order_last_30d_reduce_amount,
        sum(if(dt>=date_add('$do_date',-29),order_original_amount,0)) order_last_30d_original_amount,
        sum(if(dt>=date_add('$do_date',-29),order_final_amount,0)) order_last_30d_final_amount,
        sum(order_count) order_count,
        sum(order_reduce_amount) order_reduce_amount,
        sum(order_original_amount) order_original_amount,
        sum(order_final_amount) order_final_amount,
        sum(if(dt='$do_date',payment_count,0)) payment_last_1d_count,
        sum(if(dt='$do_date',payment_reduce_amount,0)) payment_last_1d_reduce_amount,
        sum(if(dt='$do_date',payment_amount,0)) payment_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),payment_count,0)) payment_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),payment_reduce_amount,0)) payment_last_7d_reduce_amount,
        sum(if(dt>=date_add('$do_date',-6),payment_amount,0)) payment_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),payment_count,0)) payment_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),payment_reduce_amount,0)) payment_last_30d_reduce_amount,
        sum(if(dt>=date_add('$do_date',-29),payment_amount,0)) payment_last_30d_amount,
        sum(payment_count) payment_count,
        sum(payment_reduce_amount) payment_reduce_amount,
        sum(payment_amount) payment_amount,
        sum(if(dt='$do_date',expire_count,0)) expire_last_1d_count,
        sum(if(dt>=date_add('$do_date',-6),expire_count,0)) expire_last_7d_count,
        sum(if(dt>=date_add('$do_date',-29),expire_count,0)) expire_last_30d_count,
        sum(expire_count) expire_count
    from ${APP}.dws_coupon_info_daycount
    group by coupon_id
)t2
on t1.id=t2.coupon_id;
"

dwt_activity_topic="
insert overwrite table ${APP}.dwt_activity_topic partition(dt='$do_date')
select
    t1.activity_rule_id,
    t1.activity_id,
    nvl(order_last_1d_count,0),
    nvl(order_last_1d_reduce_amount,0),
    nvl(order_last_1d_original_amount,0),
    nvl(order_last_1d_final_amount,0),
    nvl(order_count,0),
    nvl(order_reduce_amount,0),
    nvl(order_original_amount,0),
    nvl(order_final_amount,0),
    nvl(payment_last_1d_count,0),
    nvl(payment_last_1d_reduce_amount,0),
    nvl(payment_last_1d_amount,0),
    nvl(payment_count,0),
    nvl(payment_reduce_amount,0),
    nvl(payment_amount,0)
from
(
    select
        activity_rule_id,
        activity_id
    from ${APP}.dim_activity_rule_info
    where dt='$do_date'
)t1
left join
(
    select
        activity_rule_id,
        activity_id,
        sum(if(dt='$do_date',order_count,0)) order_last_1d_count,
        sum(if(dt='$do_date',order_reduce_amount,0)) order_last_1d_reduce_amount,
        sum(if(dt='$do_date',order_original_amount,0)) order_last_1d_original_amount,
        sum(if(dt='$do_date',order_final_amount,0)) order_last_1d_final_amount,
        sum(order_count) order_count,
        sum(order_reduce_amount) order_reduce_amount,
        sum(order_original_amount) order_original_amount,
        sum(order_final_amount) order_final_amount,
        sum(if(dt='$do_date',payment_count,0)) payment_last_1d_count,
        sum(if(dt='$do_date',payment_reduce_amount,0)) payment_last_1d_reduce_amount,
        sum(if(dt='$do_date',payment_amount,0)) payment_last_1d_amount,
        sum(payment_count) payment_count,
        sum(payment_reduce_amount) payment_reduce_amount,
        sum(payment_amount) payment_amount
    from ${APP}.dws_activity_info_daycount
    group by activity_rule_id,activity_id
)t2
on t1.activity_rule_id=t2.activity_rule_id
and t1.activity_id=t2.activity_id;
"

dwt_area_topic="
insert overwrite table ${APP}.dwt_area_topic partition(dt='$do_date')
select
    id,
    nvl(visit_last_1d_count,0),
    nvl(login_last_1d_count,0),
    nvl(visit_last_7d_count,0),
    nvl(login_last_7d_count,0),
    nvl(visit_last_30d_count,0),
    nvl(login_last_30d_count,0),
    nvl(visit_count,0),
    nvl(login_count,0),
    nvl(order_last_1d_count,0),
    nvl(order_last_1d_original_amount,0),
    nvl(order_last_1d_final_amount,0),
    nvl(order_last_7d_count,0),
    nvl(order_last_7d_original_amount,0),
    nvl(order_last_7d_final_amount,0),
    nvl(order_last_30d_count,0),
    nvl(order_last_30d_original_amount,0),
    nvl(order_last_30d_final_amount,0),
    nvl(order_count,0),
    nvl(order_original_amount,0),
    nvl(order_final_amount,0),
    nvl(payment_last_1d_count,0),
    nvl(payment_last_1d_amount,0),
    nvl(payment_last_7d_count,0),
    nvl(payment_last_7d_amount,0),
    nvl(payment_last_30d_count,0),
    nvl(payment_last_30d_amount,0),
    nvl(payment_count,0),
    nvl(payment_amount,0),
    nvl(refund_order_last_1d_count,0),
    nvl(refund_order_last_1d_amount,0),
    nvl(refund_order_last_7d_count,0),
    nvl(refund_order_last_7d_amount,0),
    nvl(refund_order_last_30d_count,0),
    nvl(refund_order_last_30d_amount,0),
    nvl(refund_order_count,0),
    nvl(refund_order_amount,0),
    nvl(refund_payment_last_1d_count,0),
    nvl(refund_payment_last_1d_amount,0),
    nvl(refund_payment_last_7d_count,0),
    nvl(refund_payment_last_7d_amount,0),
    nvl(refund_payment_last_30d_count,0),
    nvl(refund_payment_last_30d_amount,0),
    nvl(refund_payment_count,0),
    nvl(refund_payment_amount,0)
from
(
    select
        id
    from ${APP}.dim_base_province
)t1
left join
(
    select
        province_id province_id,
        sum(if(dt='$do_date',visit_count,0)) visit_last_1d_count,
        sum(if(dt='$do_date',login_count,0)) login_last_1d_count,
        sum(if(dt>=date_add('$do_date',-6),visit_count,0)) visit_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),login_count,0)) login_last_7d_count,
        sum(if(dt>=date_add('$do_date',-29),visit_count,0)) visit_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),login_count,0)) login_last_30d_count,
        sum(visit_count) visit_count,
        sum(login_count) login_count,
        sum(if(dt='$do_date',order_count,0)) order_last_1d_count,
        sum(if(dt='$do_date',order_original_amount,0)) order_last_1d_original_amount,
        sum(if(dt='$do_date',order_final_amount,0)) order_last_1d_final_amount,
        sum(if(dt>=date_add('$do_date',-6),order_count,0)) order_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),order_original_amount,0)) order_last_7d_original_amount,
        sum(if(dt>=date_add('$do_date',-6),order_final_amount,0)) order_last_7d_final_amount,
        sum(if(dt>=date_add('$do_date',-29),order_count,0)) order_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),order_original_amount,0)) order_last_30d_original_amount,
        sum(if(dt>=date_add('$do_date',-29),order_final_amount,0)) order_last_30d_final_amount,
        sum(order_count) order_count,
        sum(order_original_amount) order_original_amount,
        sum(order_final_amount) order_final_amount,
        sum(if(dt='$do_date',payment_count,0)) payment_last_1d_count,
        sum(if(dt='$do_date',payment_amount,0)) payment_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),payment_count,0)) payment_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),payment_amount,0)) payment_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),payment_count,0)) payment_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),payment_amount,0)) payment_last_30d_amount,
        sum(payment_count) payment_count,
        sum(payment_amount) payment_amount,
        sum(if(dt='$do_date',refund_order_count,0)) refund_order_last_1d_count,
        sum(if(dt='$do_date',refund_order_amount,0)) refund_order_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),refund_order_count,0)) refund_order_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),refund_order_amount,0)) refund_order_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),refund_order_count,0)) refund_order_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),refund_order_amount,0)) refund_order_last_30d_amount,
        sum(refund_order_count) refund_order_count,
        sum(refund_order_amount) refund_order_amount,
        sum(if(dt='$do_date',refund_payment_count,0)) refund_payment_last_1d_count,
        sum(if(dt='$do_date',refund_payment_amount,0)) refund_payment_last_1d_amount,
        sum(if(dt>=date_add('$do_date',-6),refund_payment_count,0)) refund_payment_last_7d_count,
        sum(if(dt>=date_add('$do_date',-6),refund_payment_amount,0)) refund_payment_last_7d_amount,
        sum(if(dt>=date_add('$do_date',-29),refund_payment_count,0)) refund_payment_last_30d_count,
        sum(if(dt>=date_add('$do_date',-29),refund_payment_amount,0)) refund_payment_last_30d_amount,
        sum(refund_payment_count) refund_payment_count,
        sum(refund_payment_amount) refund_payment_amount
    from ${APP}.dws_area_stats_daycount
    group by province_id
)t2
on t1.id=t2.province_id;
"


case $1 in
    "dwt_visitor_topic" )
        hive -e "$dwt_visitor_topic"
    ;;
    "dwt_user_topic" )
        hive -e "$dwt_user_topic"
    ;;
    "dwt_sku_topic" )
        hive -e "$dwt_sku_topic"
    ;;
    "dwt_activity_topic" )
        hive -e "$dwt_activity_topic"
    ;;
    "dwt_coupon_topic" )
        hive -e "$dwt_coupon_topic"
    ;;
    "dwt_area_topic" )
        hive -e "$dwt_area_topic"
    ;;
    "all" )
        hive -e "$dwt_visitor_topic$dwt_user_topic$dwt_sku_topic$dwt_activity_topic$dwt_coupon_topic$dwt_area_topic"
    ;;
esac

