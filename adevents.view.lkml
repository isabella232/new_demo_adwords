view: adevents {
  view_label: "Ad Events"
  sql_table_name: adwords.adevents ;;

  dimension: adevent_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.event_id ;;
  }

  dimension: keyword_id {
    type: number
    sql: ${TABLE}.keyword_id ;;
  }

  dimension_group: created {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      hour_of_day,
      day_of_week,
      month,
      month_num,
      quarter,
      year
    ]
    sql: ${TABLE}.created_at ;;
  }

  dimension: event_type {
    type: string
    sql: ${TABLE}.event_type ;;
  }

  dimension: is_click_event {
    type: yesno
    sql: ${event_type} = "click";;
  }
  dimension: is_impression_event {
    type: yesno
    sql: ${event_type} = "impression";;
  }

  dimension: cost_search{
    hidden: yes
    type: number
    sql: case when ${is_click_event} = true
        and ${campaigns.advertising_channel} = "Search" then (1.0*${TABLE}.cost)/100 end ;;
    value_format_name: usd
  }

  dimension: cost_display{
    hidden: yes
    type: number
    sql: case when ${is_impression_event} = true
      and ${campaigns.advertising_channel} <> "Search"
      then (1.0*${TABLE}.cost)/1000 end ;;
    value_format_name: usd
  }

  measure: total_cost_clicks {
    label: "Total Spend (Search Clicks)"
    type: sum
    sql: ${cost_search} ;;
    value_format_name: usd
  }

  measure: total_cost_impressions {
    label: "Total Spend (Display Impressions)"
    type: sum
    sql: ${cost_display} ;;
    value_format_name: usd
  }

  dimension: cost {
    type: number
    hidden: yes
    sql: ${cost_search} + ${cost_display} ;;
    value_format_name: usd
  }

  measure: total_cost {
    label: "Total Spend"
    type: number
    sql: ${total_cost_clicks} + ${total_cost_impressions} ;;
    value_format_name: usd
  }

  measure: total_cumulative_spend {
    label: "Total Spend (Cumulative)"
    type: running_total
    sql: ${total_cost_clicks} ;;
    value_format_name: usd_0
  }

  measure: total_ad_events {
    hidden: yes
    type: count
    drill_fields: [events.id, keywords.criterion_name, keywords.keyword_id]
  }

  measure: total_clicks {
    type: sum
    sql: case when ${event_type} = "click" then 1 else 0 end;;
    drill_fields: [detail*]
  }

  measure: total_impressions {
    type: sum
    sql: case when ${event_type} = "impression" then 1 else 0 end;;
    drill_fields: [detail*]

  }

  # Typically Viewability score for display
  measure: total_viewability {
    type: number
    sql: ${total_impressions} * .66 ;;
    value_format_name: decimal_0
  }

  measure: click_rate {
    label: "Click Through Rate (CTR)"
    description: "Percent of people that click on an ad."
    type: number
    sql: ${total_clicks}*1.0/nullif(${total_impressions},0) ;;
    value_format_name: percent_2
    drill_fields: [detail*]

  }

  measure: cost_per_click {
    label: "Cost per Click (CPC)"
    description: "Average cost per ad click."
    type: number
    sql: ${total_cost_clicks}* 1.0/ NULLIF(${total_clicks},0) ;;
    value_format_name: usd
    drill_fields: [detail*]
  }

  measure: cost_per_impression {
    label: "Cost per Impression (CPM)"
    description: "Average cost per ad impression for display ads."
    type: number
    sql: ${total_cost_impressions}* 1.0/ NULLIF(${total_impressions},0) ;;
    value_format_name: usd
    drill_fields: [detail*]
  }

  set: detail {
    fields: [adevent_id, keywords.criterion_name, event_type, total_cost_clicks]

  }
}
