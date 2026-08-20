USE ott_movie_analysis;

-- Platform Performance Scorecard
WITH platform_metrics AS (

    SELECT
        platform,

        COUNT(*) AS total_titles,

        ROUND(
            AVG(imdb_rating),
            2
        ) AS average_rating,

        ROUND(
            AVG(imdb_votes),
            0
        ) AS average_votes,

        ROUND(
            AVG(content_success_score),
            2
        ) AS average_success_score

    FROM ott_content

    GROUP BY platform
)

SELECT
    platform,
    total_titles,
    average_rating,
    average_votes,
    average_success_score,

    RANK() OVER (
        ORDER BY average_rating DESC
    ) AS rating_rank,

    RANK() OVER (
        ORDER BY total_titles DESC
    ) AS catalog_rank,

    RANK() OVER (
        ORDER BY average_success_score DESC
    ) AS success_rank

FROM platform_metrics
ORDER BY rating_rank;

-- Top 10 Titles for Each Platform (important interview question.)
WITH ranked_titles AS (

    SELECT
        title,
        platform,
        release_year,
        imdb_rating,
        imdb_votes,

        ROW_NUMBER() OVER (
            PARTITION BY platform
            ORDER BY
                imdb_rating DESC,
                imdb_votes DESC
        ) AS title_rank

    FROM ott_content

    WHERE imdb_votes >= 10000
)

SELECT
    platform,
    title_rank,
    title,
    release_year,
    imdb_rating,
    imdb_votes

FROM ranked_titles

WHERE title_rank <= 10

ORDER BY
    platform,
    title_rank;
    
-- RANK vs DENSE_RANK
SELECT
    title,
    platform,
    imdb_rating,

    RANK() OVER (
        ORDER BY imdb_rating DESC
    ) AS rating_rank,

    DENSE_RANK() OVER (
        ORDER BY imdb_rating DESC
    ) AS dense_rating_rank

FROM ott_content

WHERE imdb_votes >= 10000

ORDER BY imdb_rating DESC
LIMIT 30;

-- Platform Rating Distribution
SELECT
    platform,

    CASE
        WHEN imdb_rating >= 9 THEN 'Masterpiece'
        WHEN imdb_rating >= 8 THEN 'Excellent'
        WHEN imdb_rating >= 7 THEN 'Good'
        WHEN imdb_rating >= 6 THEN 'Average'
        ELSE 'Low Rated'
    END AS rating_category,

    COUNT(*) AS title_count

FROM ott_content

GROUP BY
    platform,
    rating_category

ORDER BY
    platform,
    title_count DESC;

-- Percentage of High-Rated Content (Business question:- Which platform has the highest percentage of titles rated 7+?)
SELECT
    platform,

    COUNT(*) AS total_titles,

    SUM(
        CASE
            WHEN imdb_rating >= 7
            THEN 1
            ELSE 0
        END
    ) AS high_rated_titles,

    ROUND(
        SUM(
            CASE
                WHEN imdb_rating >= 7
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS high_rated_percentage

FROM ott_content

GROUP BY platform

ORDER BY high_rated_percentage DESC;

-- Excellent Content Percentage
SELECT
    platform,

    COUNT(*) AS total_titles,

    SUM(
        CASE
            WHEN imdb_rating >= 8
            THEN 1
            ELSE 0
        END
    ) AS excellent_titles,

    ROUND(
        SUM(
            CASE
                WHEN imdb_rating >= 8
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS excellent_percentage

FROM ott_content

GROUP BY platform

ORDER BY excellent_percentage DESC;

-- Most Popular Titles by Platform
WITH popularity_rank AS (

    SELECT
        title,
        platform,
        imdb_rating,
        imdb_votes,

        ROW_NUMBER() OVER (
            PARTITION BY platform
            ORDER BY imdb_votes DESC
        ) AS popularity_rank

    FROM ott_content
)

SELECT
    platform,
    popularity_rank,
    title,
    imdb_rating,
    imdb_votes

FROM popularity_rank

WHERE popularity_rank <= 10

ORDER BY
    platform,
    popularity_rank;

-- Yearly Content Trend
SELECT
    release_year,
    COUNT(*) AS total_titles,
    ROUND(
        AVG(imdb_rating),
        2
    ) AS average_rating

FROM ott_content

WHERE release_year IS NOT NULL

GROUP BY release_year

ORDER BY release_year;

-- Year-over-Year Growth
WITH yearly_data AS (

    SELECT
        release_year,
        COUNT(*) AS title_count

    FROM ott_content

    WHERE release_year IS NOT NULL

    GROUP BY release_year
)

SELECT
    release_year,
    title_count,

    LAG(title_count) OVER (
        ORDER BY release_year
    ) AS previous_year_count,

    title_count -
    LAG(title_count) OVER (
        ORDER BY release_year
    ) AS change_in_titles,

    ROUND(
        (
            title_count -
            LAG(title_count) OVER (
                ORDER BY release_year
            )
        )
        /
        NULLIF(
            LAG(title_count) OVER (
                ORDER BY release_year
            ),
            0
        ) * 100,
        2
    ) AS yoy_growth_percentage

FROM yearly_data

ORDER BY release_year;

-- Platform Year-over-Year Growth
WITH yearly_platform AS (

    SELECT
        platform,
        release_year,
        COUNT(*) AS title_count

    FROM ott_content

    WHERE release_year IS NOT NULL

    GROUP BY
        platform,
        release_year
),

growth_data AS (

    SELECT
        platform,
        release_year,
        title_count,

        LAG(title_count) OVER (
            PARTITION BY platform
            ORDER BY release_year
        ) AS previous_year_count

    FROM yearly_platform
)

SELECT
    platform,
    release_year,
    title_count,
    previous_year_count,

    ROUND(
        (
            title_count -
            previous_year_count
        )
        /
        NULLIF(
            previous_year_count,
            0
        ) * 100,
        2
    ) AS yoy_growth_percentage

FROM growth_data

ORDER BY
    platform,
    release_year;
    
-- Best Rated Year by Platform
WITH yearly_platform AS (

    SELECT
        platform,
        release_year,
        COUNT(*) AS title_count,
        AVG(imdb_rating) AS average_rating

    FROM ott_content

    WHERE release_year IS NOT NULL

    GROUP BY
        platform,
        release_year
),

ranked_years AS (

    SELECT
        platform,
        release_year,
        title_count,
        average_rating,

        RANK() OVER (
            PARTITION BY platform
            ORDER BY average_rating DESC
        ) AS rating_rank

    FROM yearly_platform

    WHERE title_count >= 20
)

SELECT
    platform,
    release_year,
    title_count,
    ROUND(
        average_rating,
        2
    ) AS average_rating

FROM ranked_years

WHERE rating_rank = 1

ORDER BY platform;

-- Most Productive Year by Platform
WITH yearly_platform AS (

    SELECT
        platform,
        release_year,
        COUNT(*) AS title_count

    FROM ott_content

    WHERE release_year IS NOT NULL

    GROUP BY
        platform,
        release_year
),

ranked_years AS (

    SELECT
        platform,
        release_year,
        title_count,

        RANK() OVER (
            PARTITION BY platform
            ORDER BY title_count DESC
        ) AS volume_rank

    FROM yearly_platform
)

SELECT
    platform,
    release_year,
    title_count

FROM ranked_years

WHERE volume_rank = 1

ORDER BY platform;

-- Average Rating by Decade
SELECT
    FLOOR(release_year / 10) * 10 AS decade,

    COUNT(*) AS total_titles,

    ROUND(
        AVG(imdb_rating),
        2
    ) AS average_rating,

    ROUND(
        AVG(imdb_votes),
        0
    ) AS average_votes

FROM ott_content

WHERE release_year IS NOT NULL

GROUP BY decade

ORDER BY decade;

-- Platform × Decade
SELECT
    platform,

    FLOOR(release_year / 10) * 10
        AS decade,

    COUNT(*) AS title_count,

    ROUND(
        AVG(imdb_rating),
        2
    ) AS average_rating

FROM ott_content

WHERE release_year IS NOT NULL

GROUP BY
    platform,
    decade

ORDER BY
    platform,
    decade;
    
-- Highest-Rated Content Within Each Genre
SELECT
    genres,
    COUNT(*) AS title_count,
    ROUND(
        AVG(imdb_rating),
        2
    ) AS average_rating

FROM ott_content

WHERE genres IS NOT NULL

GROUP BY genres

HAVING COUNT(*) >= 20

ORDER BY average_rating DESC

LIMIT 20;

-- Platform Success Score Ranking
WITH platform_scores AS (

    SELECT
        platform,

        COUNT(*) AS total_titles,

        AVG(imdb_rating)
            AS average_rating,

        AVG(content_success_score)
            AS success_score

    FROM ott_content

    GROUP BY platform
),

ranked_platforms AS (

    SELECT
        *,

        RANK() OVER (
            ORDER BY success_score DESC
        ) AS success_rank

    FROM platform_scores
)

SELECT
    platform,
    total_titles,
    ROUND(average_rating, 2)
        AS average_rating,
    ROUND(success_score, 2)
        AS success_score,
    success_rank

FROM ranked_platforms

ORDER BY success_rank;

-- Find Titles That Are Both Highly Rated AND Popular
SELECT
    title,
    platform,
    release_year,
    imdb_rating,
    imdb_votes,
    content_success_score

FROM ott_content

WHERE imdb_rating >= 8
  AND imdb_votes >= 100000

ORDER BY
    imdb_rating DESC,
    imdb_votes DESC;
    
-- Find Hidden Gems (Which highly-rated titles may be under-discovered?)
SELECT
    title,
    platform,
    release_year,
    imdb_rating,
    imdb_votes

FROM ott_content

WHERE imdb_rating >= 8
  AND imdb_votes < 10000

ORDER BY
    imdb_rating DESC;

-- Find Overhyped / Low-Rated Popular Titles (Highly visible but poorly rated content.)
SELECT
    title,
    platform,
    release_year,
    imdb_rating,
    imdb_votes

FROM ott_content

WHERE imdb_votes >= 100000
  AND imdb_rating < 6

ORDER BY
    imdb_votes DESC;
    
-- Platform Content Quality Matrix
SELECT
    platform,

    COUNT(*) AS total_titles,

    ROUND(
        AVG(imdb_rating),
        2
    ) AS avg_rating,

    ROUND(
        AVG(imdb_votes),
        0
    ) AS avg_votes,

    SUM(
        CASE
            WHEN imdb_rating >= 8
            THEN 1
            ELSE 0
        END
    ) AS excellent_titles,

    SUM(
        CASE
            WHEN imdb_rating >= 8
             AND imdb_votes >= 100000
            THEN 1
            ELSE 0
        END
    ) AS popular_excellent_titles,

    SUM(
        CASE
            WHEN imdb_rating >= 8
             AND imdb_votes < 10000
            THEN 1
            ELSE 0
        END
    ) AS hidden_gems

FROM ott_content

GROUP BY platform

ORDER BY avg_rating DESC;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- ADVANCE ANALYSIS AFTER NORMALIZATION
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

USE ott_movie_analysis;

-- Database Overview
SELECT
    'Platforms' AS table_name,
    COUNT(*) AS total_records
FROM platforms

UNION ALL

SELECT
    'Titles',
    COUNT(*)
FROM titles

UNION ALL

SELECT
    'Genres',
    COUNT(*)
FROM genres

UNION ALL

SELECT
    'Title-Genre Relationships',
    COUNT(*)
FROM title_genres

UNION ALL

SELECT
    'Excluded Titles',
    COUNT(*)
FROM excluded_titles;

--
--
SELECT
    p.platform_name,

    COUNT(DISTINCT t.title_id) AS total_titles,

    ROUND(
        AVG(t.imdb_rating),
        2
    ) AS average_rating,

    ROUND(
        AVG(t.imdb_votes),
        0
    ) AS average_votes,

    SUM(t.imdb_votes) AS total_votes

FROM titles t

JOIN platforms p
    ON t.platform_id = p.platform_id

WHERE t.imdb_rating IS NOT NULL

GROUP BY
    p.platform_name

ORDER BY
    average_rating DESC;
    
-- Platform Rating Ranking
WITH platform_metrics AS (

    SELECT
        p.platform_name,

        COUNT(DISTINCT t.title_id) AS total_titles,

        AVG(t.imdb_rating) AS average_rating,

        AVG(t.imdb_votes) AS average_votes,

        SUM(t.imdb_votes) AS total_votes

    FROM titles t

    JOIN platforms p
        ON t.platform_id = p.platform_id

    WHERE t.imdb_rating IS NOT NULL

    GROUP BY
        p.platform_name
)

SELECT
    platform_name,
    total_titles,
    ROUND(average_rating, 2) AS average_rating,
    ROUND(average_votes, 0) AS average_votes,
    total_votes,

    RANK() OVER (
        ORDER BY average_rating DESC
    ) AS rating_rank

FROM platform_metrics

ORDER BY rating_rank;

-- Top 10 Highest-Rated Titles
SELECT
    t.title,
    p.platform_name,
    t.release_year,
    t.imdb_rating,
    t.imdb_votes
FROM titles t
JOIN platforms p
    ON t.platform_id = p.platform_id
WHERE t.imdb_rating IS NOT NULL
ORDER BY
    t.imdb_rating DESC,
    t.imdb_votes DESC
LIMIT 10;

-- Most Popular Titles
SELECT
    t.title,
    p.platform_name,
    t.release_year,
    t.imdb_rating,
    t.imdb_votes
FROM titles t
JOIN platforms p
    ON t.platform_id = p.platform_id
WHERE t.imdb_votes IS NOT NULL
ORDER BY
    t.imdb_votes DESC
LIMIT 10;

-- Rating vs Popularity
SELECT
    ROUND(AVG(imdb_rating), 2) AS avg_rating,
    ROUND(AVG(imdb_votes), 0) AS avg_votes
FROM titles
WHERE imdb_rating IS NOT NULL
  AND imdb_votes IS NOT NULL;
  
-- Rating vs Popularity Classification
SELECT
    t.title,
    p.platform_name,
    t.release_year,
    t.imdb_rating,
    t.imdb_votes,

    CASE
        WHEN t.imdb_rating >= 6.22
             AND t.imdb_votes >= 38226
            THEN 'High Rating + High Popularity'

        WHEN t.imdb_rating >= 6.22
             AND t.imdb_votes < 38226
            THEN 'High Rating + Low Popularity'

        WHEN t.imdb_rating < 6.22
             AND t.imdb_votes >= 38226
            THEN 'Low Rating + High Popularity'

        ELSE
            'Low Rating + Low Popularity'
    END AS performance_category

FROM titles t

JOIN platforms p
    ON t.platform_id = p.platform_id

WHERE
    t.imdb_rating IS NOT NULL
    AND t.imdb_votes IS NOT NULL

ORDER BY
    t.imdb_rating DESC,
    t.imdb_votes DESC;
    
-- Count Each Category
SELECT
    CASE
        WHEN imdb_rating >= 6.22
             AND imdb_votes >= 38226
            THEN 'High Rating + High Popularity'

        WHEN imdb_rating >= 6.22
             AND imdb_votes < 38226
            THEN 'High Rating + Low Popularity'

        WHEN imdb_rating < 6.22
             AND imdb_votes >= 38226
            THEN 'Low Rating + High Popularity'

        ELSE
            'Low Rating + Low Popularity'
    END AS performance_category,

    COUNT(*) AS title_count

FROM titles

WHERE
    imdb_rating IS NOT NULL
    AND imdb_votes IS NOT NULL

GROUP BY
    performance_category

ORDER BY
    title_count DESC;
    
-- Platform-wise Performance Categories
SELECT
    p.platform_name,

    CASE
        WHEN t.imdb_rating >= 6.22
             AND t.imdb_votes >= 38226
            THEN 'High Rating + High Popularity'

        WHEN t.imdb_rating >= 6.22
             AND t.imdb_votes < 38226
            THEN 'High Rating + Low Popularity'

        WHEN t.imdb_rating < 6.22
             AND t.imdb_votes >= 38226
            THEN 'Low Rating + High Popularity'

        ELSE
            'Low Rating + Low Popularity'
    END AS performance_category,

    COUNT(*) AS title_count

FROM titles t

JOIN platforms p
    ON t.platform_id = p.platform_id

WHERE
    t.imdb_rating IS NOT NULL
    AND t.imdb_votes IS NOT NULL

GROUP BY
    p.platform_name,
    performance_category

ORDER BY
    p.platform_name,
    title_count DESC;
    
-- Platform-wise Performance Matrix
SELECT
    p.platform_name,

    CASE
        WHEN t.imdb_rating >= 6.22
             AND t.imdb_votes >= 38226
            THEN 'High Rating + High Popularity'

        WHEN t.imdb_rating >= 6.22
             AND t.imdb_votes < 38226
            THEN 'High Rating + Low Popularity'

        WHEN t.imdb_rating < 6.22
             AND t.imdb_votes >= 38226
            THEN 'Low Rating + High Popularity'

        ELSE
            'Low Rating + Low Popularity'
    END AS performance_category,

    COUNT(*) AS title_count

FROM titles t

JOIN platforms p
    ON t.platform_id = p.platform_id

WHERE
    t.imdb_rating IS NOT NULL
    AND t.imdb_votes IS NOT NULL

GROUP BY
    p.platform_name,
    performance_category

ORDER BY
    p.platform_name,
    title_count DESC;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --   
-- Genre Performance Analysis
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- Genre Performance Summary
SELECT
    g.genre_name,

    COUNT(DISTINCT t.title_id) AS total_titles,

    ROUND(
        AVG(t.imdb_rating),
        2
    ) AS average_rating,

    ROUND(
        AVG(t.imdb_votes),
        0
    ) AS average_votes,

    SUM(t.imdb_votes) AS total_votes

FROM genres g

JOIN title_genres tg
    ON g.genre_id = tg.genre_id

JOIN titles t
    ON tg.title_id = t.title_id

WHERE
    t.imdb_rating IS NOT NULL

GROUP BY
    g.genre_name

HAVING
    COUNT(DISTINCT t.title_id) >= 20

ORDER BY
    average_rating DESC;

-- Top Genres by Content Volume (Which genres have the largest number of titles in the OTT database?)
SELECT
    g.genre_name,
    COUNT(DISTINCT tg.title_id) AS total_titles
FROM genres g
JOIN title_genres tg
    ON g.genre_id = tg.genre_id
JOIN titles t
    ON tg.title_id = t.title_id
GROUP BY
    g.genre_name
ORDER BY
    total_titles DESC
LIMIT 15;

-- Genre Ranking Using RANK()
WITH genre_metrics AS (

    SELECT
        g.genre_name,

        COUNT(DISTINCT tg.title_id) AS total_titles,

        AVG(t.imdb_rating) AS average_rating

    FROM genres g

    JOIN title_genres tg
        ON g.genre_id = tg.genre_id

    JOIN titles t
        ON tg.title_id = t.title_id

    WHERE
        t.imdb_rating IS NOT NULL

    GROUP BY
        g.genre_name

    HAVING
        COUNT(DISTINCT tg.title_id) >= 20
)

SELECT
    genre_name,
    total_titles,
    ROUND(average_rating, 2) AS average_rating,

    RANK() OVER (
        ORDER BY average_rating DESC
    ) AS genre_rank

FROM genre_metrics

ORDER BY
    genre_rank;

-- Top 10 Genres by Audience Engagement
SELECT
    g.genre_name,

    COUNT(DISTINCT tg.title_id) AS total_titles,

    SUM(t.imdb_votes) AS total_votes,

    ROUND(
        AVG(t.imdb_votes),
        0
    ) AS average_votes

FROM genres g

JOIN title_genres tg
    ON g.genre_id = tg.genre_id

JOIN titles t
    ON tg.title_id = t.title_id

WHERE
    t.imdb_votes IS NOT NULL

GROUP BY
    g.genre_name

ORDER BY
    total_votes DESC

LIMIT 10;

-- High-Rating + High-Engagement Genres
SELECT
    g.genre_name,

    COUNT(DISTINCT tg.title_id) AS total_titles,

    ROUND(AVG(t.imdb_rating), 2) AS average_rating,

    ROUND(AVG(t.imdb_votes), 0) AS average_votes

FROM genres g

JOIN title_genres tg
    ON g.genre_id = tg.genre_id

JOIN titles t
    ON tg.title_id = t.title_id

WHERE
    t.imdb_rating IS NOT NULL
    AND t.imdb_votes IS NOT NULL

GROUP BY
    g.genre_name

HAVING
    COUNT(DISTINCT tg.title_id) >= 20
    AND AVG(t.imdb_rating) >= 6.22
    AND AVG(t.imdb_votes) >= 38226

ORDER BY
    average_rating DESC;
    
-- Best Genre on Each Platform
WITH genre_platform AS (

    SELECT
        p.platform_name,
        g.genre_name,

        COUNT(DISTINCT t.title_id) AS title_count,

        AVG(t.imdb_rating) AS average_rating,

        AVG(t.imdb_votes) AS average_votes

    FROM titles t

    JOIN platforms p
        ON t.platform_id = p.platform_id

    JOIN title_genres tg
        ON t.title_id = tg.title_id

    JOIN genres g
        ON tg.genre_id = g.genre_id

    WHERE
        t.imdb_rating IS NOT NULL
        AND t.imdb_votes IS NOT NULL

    GROUP BY
        p.platform_name,
        g.genre_name

    HAVING
        COUNT(DISTINCT t.title_id) >= 20
),

ranked AS (

    SELECT
        *,
        RANK() OVER (
            PARTITION BY platform_name
            ORDER BY average_rating DESC
        ) AS genre_rank

    FROM genre_platform
)

SELECT
    platform_name,
    genre_name,
    title_count,
    ROUND(average_rating, 2) AS average_rating,
    ROUND(average_votes, 0) AS average_votes

FROM ranked

WHERE genre_rank = 1

ORDER BY
    platform_name;
    
-- Platform × Genre Analysis
WITH platform_genre AS (

    SELECT
        p.platform_name,
        g.genre_name,

        COUNT(DISTINCT t.title_id) AS title_count,

        AVG(t.imdb_rating) AS avg_rating,

        AVG(t.imdb_votes) AS avg_votes

    FROM titles t

    JOIN platforms p
        ON t.platform_id = p.platform_id

    JOIN title_genres tg
        ON t.title_id = tg.title_id

    JOIN genres g
        ON tg.genre_id = g.genre_id

    WHERE
        t.imdb_rating IS NOT NULL

    GROUP BY
        p.platform_name,
        g.genre_name

    HAVING
        COUNT(DISTINCT t.title_id) >= 20
),

ranked AS (

    SELECT
        *,
        RANK() OVER (
            PARTITION BY platform_name
            ORDER BY avg_rating DESC
        ) AS genre_rank

    FROM platform_genre
)

SELECT
    platform_name,
    genre_name,
    title_count,
    ROUND(avg_rating, 2) AS avg_rating,
    ROUND(avg_votes, 0) AS avg_votes

FROM ranked

WHERE genre_rank = 1

ORDER BY platform_name;

-- Top 5 Titles Per Platform
WITH ranked_titles AS (

    SELECT
        p.platform_name,
        t.title,
        t.release_year,
        t.imdb_rating,
        t.imdb_votes,

        ROW_NUMBER() OVER (
            PARTITION BY p.platform_name
            ORDER BY
                t.imdb_rating DESC,
                t.imdb_votes DESC
        ) AS ranking

    FROM titles t

    JOIN platforms p
        ON t.platform_id = p.platform_id

    WHERE t.imdb_rating IS NOT NULL
)

SELECT
    platform_name,
    ranking,
    title,
    release_year,
    imdb_rating,
    imdb_votes

FROM ranked_titles

WHERE ranking <= 5

ORDER BY
    platform_name,
    ranking;
    
-- Multi-Platform Content
SELECT
    title,

    COUNT(DISTINCT platform_id) AS platform_count,

    GROUP_CONCAT(
        DISTINCT p.platform_name
        ORDER BY p.platform_name
        SEPARATOR ', '
    ) AS available_on

FROM titles t

JOIN platforms p
    ON t.platform_id = p.platform_id

GROUP BY
    title

HAVING
    COUNT(DISTINCT platform_id) > 1

ORDER BY
    platform_count DESC,
    title;
    
