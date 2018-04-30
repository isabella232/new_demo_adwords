view: sessions {
  derived_table: {
    sql_trigger_value: select count(*) from events ;;
    sql:
      SELECT
        rank() over (partition by session_user_id order by session_end) as session_rank
        , *
      FROM(
      SELECT
        session_id
        , MIN(created_at) AS session_start
        , MAX(created_at) AS session_end
        , COUNT(*) AS number_of_events_in_session
        , SUM(CASE WHEN event_type IN ('Category','Brand') THEN 1 else 0 END) AS browse_events
        , SUM(CASE WHEN event_type = 'Product' THEN 1 else 0 END) AS product_events
        , SUM(CASE WHEN event_type = 'Cart' THEN 1 else 0 END) AS cart_events
        , SUM(CASE WHEN event_type = 'Purchase' THEN 1 else 0 end) AS purchase_events
        , MAX(user_id) AS session_user_id
        , MIN(id) AS landing_event_id
        , MAX(id) AS bounce_event_id
        , MAX(traffic_source) AS traffic_source
        , MAX(ad_event_id) AS ad_event_id
      FROM adwords.events
      GROUP BY session_id
      )
;;
  }

  #####  Basic Web Info  ########

  dimension: session_id {
    type: string
    hidden: yes
    primary_key: yes
    sql: ${TABLE}.session_id ;;
  }

  dimension: rank {
    type: number
    sql: ${TABLE}.session_rank ;;
  }

  dimension: traffic_source {
    type: string
  }

  dimension: ad_event_id {
    type: number
  }

  dimension: session_rank {
    type: number
    sql: ${TABLE}.session_rank ;;
  }

  dimension: session_user_id {
    sql: ${TABLE}.session_user_id ;;
  }

  dimension: landing_event_id {
    sql: ${TABLE}.landing_event_id ;;
  }

  dimension: bounce_event_id {
    sql: ${TABLE}.bounce_event_id ;;
  }

  dimension_group: session_start {
    type: time
    timeframes: [raw, time, date, week, month, hour_of_day, day_of_week]
    sql: ${TABLE}.session_start ;;
  }

  dimension_group: session_end {
    type: time
    timeframes: [raw, time, date, week, month]
    sql: ${TABLE}.session_end ;;
  }

  dimension: duration {
    label: "Duration (sec)"
    type: number
    sql: DATEDIFF('second', ${session_start_raw}, ${session_end_raw}) ;;
  }

  measure: average_duration {
    label: "Average Duration (sec)"
    type: average
    value_format_name: decimal_2
    sql: ${duration} ;;
  }

  dimension: duration_seconds_tier {
    label: "Duration Tier (sec)"
    type: tier
    tiers: [10, 30, 60, 120, 300]
    style: integer
    sql: ${duration} ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  #####  Bounce Information  ########

  dimension: is_bounce_session {
    type: yesno
    sql: ${number_of_events_in_session} = 1 ;;
  }

  measure: count_bounce_sessions {
    type: count

    filters: {
      field: is_bounce_session
      value: "Yes"
    }

    drill_fields: [detail*]
  }

  measure: percent_bounce_sessions {
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${count_bounce_sessions} / nullif(${count},0) ;;
  }

  ####### Session by event types included  ########

  dimension: number_of_browse_events_in_session {
    type: number
    hidden: yes
    sql: ${TABLE}.browse_events ;;
  }

  dimension: number_of_product_events_in_session {
    type: number
    hidden: yes
    sql: ${TABLE}.product_events ;;
  }

  dimension: number_of_cart_events_in_session {
    type: number
    hidden: yes
    sql: ${TABLE}.cart_events ;;
  }

  dimension: number_of_purchase_events_in_session {
    type: number
    hidden: yes
    sql: ${TABLE}.purchase_events ;;
  }

  dimension: includes_browse {
    type: yesno
    sql: ${number_of_browse_events_in_session} > 0 ;;
  }

  dimension: includes_product {
    type: yesno
    sql: ${number_of_product_events_in_session} > 0 ;;
  }

  dimension: includes_cart {
    type: yesno
    sql: ${number_of_cart_events_in_session} > 0 ;;
  }

  dimension: includes_purchase {
    type: yesno
    sql: ${number_of_purchase_events_in_session} > 0 ;;
  }

  measure: count_with_cart {
    type: count

    filters: {
      field: includes_cart
      value: "Yes"
    }

    drill_fields: [detail*]
  }

  measure: count_with_purchase {
    type: count

    filters: {
      field: includes_purchase
      value: "Yes"
    }

    drill_fields: [detail*]
  }

  dimension: number_of_events_in_session {
    type: number
    sql: ${TABLE}.number_of_events_in_session ;;
  }

  ####### Linear Funnel   ########

  dimension: furthest_funnel_step {
    sql: CASE
      WHEN ${number_of_purchase_events_in_session} > 0 THEN '(5) Purchase'
      WHEN ${number_of_cart_events_in_session} > 0 THEN '(4) Add to Cart'
      WHEN ${number_of_product_events_in_session} > 0 THEN '(3) View Product'
      WHEN ${number_of_browse_events_in_session} > 0 THEN '(2) Browse'
      ELSE '(1) Land'
      END
       ;;
  }

  measure: all_sessions {
    view_label: "Funnel View"
    label: "(1) All Sessions"
    type: count
    drill_fields: [detail*]
  }

  measure: count_browse_or_later {
    view_label: "Funnel View"
    label: "(2) Browse or later"
    type: count

    filters: {
      field: furthest_funnel_step
      value: "(2) Browse,(3) View Product,(4) Add to Cart,(5) Purchase
      "
    }

    drill_fields: [detail*]
  }

  measure: count_product_or_later {
    view_label: "Funnel View"
    label: "(3) View Product or later"
    type: count

    filters: {
      field: furthest_funnel_step
      value: "(3) View Product,(4) Add to Cart,(5) Purchase
      "
    }

    drill_fields: [detail*]
  }

  measure: count_cart_or_later {
    view_label: "Funnel View"
    label: "(4) Add to Cart or later"
    type: count

    filters: {
      field: furthest_funnel_step
      value: "(4) Add to Cart,(5) Purchase
      "
    }

    drill_fields: [detail*]
  }

  measure: count_purchase {
    view_label: "Funnel View"
    label: "(5) Purchase"
    type: count

    filters: {
      field: furthest_funnel_step
      value: "(5) Purchase
      "
    }

    drill_fields: [detail*]
  }

  measure: cart_to_checkout_conversion {
    view_label: "Funnel View"
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${count_purchase} / nullif(${count_cart_or_later},0) ;;
  }

  measure: overall_conversion {
    view_label: "Funnel View"
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${count_purchase} / nullif(${count},0) ;;
  }

  ### Acquisition Info
  dimension: is_first {
    type: yesno
    sql: ${session_rank} = 1 ;;
  }
  measure: acquisition_source {
    type: string
    sql: max(if(${is_first},${sessions.traffic_source},null)) ;;
  }
  measure: acquisition_ad_event_id {
    type: number
    sql: max(if(${is_first},${sessions.ad_event_id},null)) ;;
  }



  set: detail {
    fields: [session_id, session_start_time, session_end_time, number_of_events_in_session, duration, number_of_purchase_events_in_session, number_of_cart_events_in_session]
  }
}
