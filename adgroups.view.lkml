view: adgroups {
  sql_table_name: adwords.adgroups ;;

  dimension: ad_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.ad_id ;;
  }

  dimension: ad_type {
    type: string
    sql: ${TABLE}.ad_type ;;
  }

  dimension: campaign_id {
    type: number
    hidden: yes
    sql: ${TABLE}.campaign_id ;;
  }

  dimension_group: created {
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.created_at ;;
  }

  dimension: headline {
    type: string
    sql: ${TABLE}.headline ;;
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }

  dimension: period {
    type: number
    sql: ${TABLE}.period ;;
  }

  measure: count {
    type: count
    drill_fields: [campaigns.campaign_name, name, ad_type, created_date]
  }
}
