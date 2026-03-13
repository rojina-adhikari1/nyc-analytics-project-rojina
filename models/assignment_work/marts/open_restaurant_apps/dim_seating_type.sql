-- Seating type dimension for open restaurant seating applications
WITH seating_types AS (
   SELECT DISTINCT
       seating_interest_sidewalk AS seating_interest,
-- Convert raw approval values to boolean (TRUE/FALSE)
        CASE 
            WHEN approved_for_sidewalk_seating = 'Yes' THEN TRUE
            ELSE FALSE
        END AS approved_for_sidewalk,
        
        CASE 
            WHEN approved_for_roadway_seating = 'Yes' THEN TRUE
            ELSE FALSE
        END AS approved_for_roadway

    FROM {{ ref('stg_open_restaurant_applications') }} 
      AS approved_for_roadway
   FROM --TODO: reference the appropriate staging table!
   WHERE seating_interest_sidewalk IS NOT NULL
),
seating_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key([
           'seating_interest',
           'approved_for_sidewalk',
           'approved_for_roadway'
       ]) }} AS seating_type_key,

       -- TODO: fill in the rest of this SELECT statement
       --  based on the dimensional model!
       seating_interest,
       approved_for_sidewalk,
       approved_for_roadway
   FROM seating_types
)

SELECT * FROM seating_dimension