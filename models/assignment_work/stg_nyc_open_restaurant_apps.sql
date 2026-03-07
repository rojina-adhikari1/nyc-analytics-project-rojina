-- Clean and standardize NYC Open Restaurant Outdoor Seating Applications
-- One row per restaurant application

WITH source AS (

    SELECT *
    FROM {{ source('raw', 'source_nyc_open_restaurant_apps_history') }}

),

cleaned AS (

    SELECT

        -- Get all columns except ones we are transforming
        * EXCEPT (
            objectid,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            seating_interest_sidewalk,
            bulding_number,
            building_number,
            street,
            borough,
            zip,
            business_address,
            food_service_establishment,
            sla_serial_number,
            sla_license_type,
            qualify_alcohol,
            sidewalk_dimensions_length,
            sidewalk_dimensions_width,
            sidewalk_dimensions_area,
            roadway_dimensions_length,
            roadway_dimensions_width,
            roadway_dimensions_area,
            approved_for_sidewalk_seating,
            approved_for_roadway_seating,
            landmark_district_or_building,
            landmarkdistrict_terms,
            healthcompliance_terms,
            latitude,
            longitude,
            community_board,
            council_district,
            census_tract,
            bin,
            bbl,
            nta,
            time_of_submission
        ),

        -- Identifier
        CAST(objectid AS STRING) AS application_id,

        -- Restaurant information
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        CAST(doing_business_as_dba AS STRING) AS dba_name,

        -- Seating interest
        UPPER(TRIM(CAST(seating_interest_sidewalk AS STRING))) AS seating_interest,

        -- Location fields
        CAST(street AS STRING) AS street_name,

        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN','NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX','THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN','KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS','QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND','RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Clean zip codes
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A','NA') THEN NULL
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10
                 AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
            THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip_code,

        CAST(business_address AS STRING) AS business_address,

        -- Permit / license info
        CAST(food_service_establishment AS STRING) AS food_service_establishment,
        CAST(sla_serial_number AS STRING) AS sla_serial_number,
        CAST(sla_license_type AS STRING) AS sla_license_type,
        CAST(qualify_alcohol AS STRING) AS qualify_alcohol,

        -- Sidewalk dimensions
        CAST(sidewalk_dimensions_length AS FLOAT64) AS sidewalk_length_ft,
        CAST(sidewalk_dimensions_width AS FLOAT64) AS sidewalk_width_ft,
        CAST(sidewalk_dimensions_area AS FLOAT64) AS sidewalk_area_sqft,

        -- Roadway dimensions
        CAST(roadway_dimensions_length AS FLOAT64) AS roadway_length_ft,
        CAST(roadway_dimensions_width AS FLOAT64) AS roadway_width_ft,
        CAST(roadway_dimensions_area AS FLOAT64) AS roadway_area_sqft,

        -- Approval status
        CAST(approved_for_sidewalk_seating AS STRING) AS sidewalk_seating_approved,
        CAST(approved_for_roadway_seating AS STRING) AS roadway_seating_approved,

        -- Compliance
        CAST(landmark_district_or_building AS STRING) AS landmark_status,
        CAST(landmarkdistrict_terms AS STRING) AS landmark_terms_agreed,
        CAST(healthcompliance_terms AS STRING) AS health_compliance,

        -- Geographic location
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- Administrative areas
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(bin AS STRING) AS bin,
        CAST(bbl AS STRING) AS bbl,
        CAST(nta AS STRING) AS nta,

        -- Submission timestamp
        CAST(time_of_submission AS TIMESTAMP) AS submitted_at,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at,

        -- Bulding number
        -- Building number (fix Socrata typo column)

        CASE
            WHEN LOWER(TRIM(bulding_number)) = 'undefined' THEN NULL
            ELSE TRIM(CAST(bulding_number AS STRING))
        END AS building_number

    FROM source

    -- Filters
    WHERE objectid IS NOT NULL
      AND borough IS NOT NULL
      AND time_of_submission IS NOT NULL

    -- Deduplicate records
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY time_of_submission DESC
    ) = 1
)

SELECT *
FROM cleaned
