USE ott_movie_analysis;

-- 1. Total records
SELECT
    COUNT(*) AS total_titles
FROM ott_content;


-- 2. Platform distribution
SELECT
    platform,
    COUNT(*) AS total_titles
FROM ott_content
GROUP BY platform
ORDER BY total_titles DESC;


-- 3. Average rating
SELECT
    ROUND(
        AVG(imdb_rating),
        2
    ) AS average_imdb_rating
FROM ott_content;


-- 4. Rating by platform
SELECT
    platform,
    COUNT(*) AS total_titles,
    ROUND(
        AVG(imdb_rating),
        2
    ) AS average_rating
FROM ott_content
GROUP BY platform
ORDER BY average_rating DESC;

-- Business Query
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
    ) AS average_votes
FROM ott_content
GROUP BY platform
ORDER BY average_rating DESC;

-- Top Rated Movies/Shows
SELECT
    title,
    platform,
    release_year,
    imdb_rating,
    imdb_votes
FROM ott_content
ORDER BY imdb_rating DESC
LIMIT 20;

-- More Reliable Top Rated Titles
SELECT
    title,
    platform,
    release_year,
    imdb_rating,
    imdb_votes
FROM ott_content
WHERE imdb_votes >= 10000
ORDER BY
    imdb_rating DESC,
    imdb_votes DESC
LIMIT 20;

-- Platform Top 10
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
        ) AS rank_number

    FROM ott_content

    WHERE imdb_votes >= 10000
)

SELECT
    title,
    platform,
    release_year,
    imdb_rating,
    imdb_votes,
    rank_number
FROM ranked_titles
WHERE rank_number <= 10
ORDER BY
    platform,
    rank_number;

-- Movie vs TV Analysis
SELECT
    content_type,
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
GROUP BY content_type
ORDER BY average_rating DESC;

-- Platform × Content Type
SELECT
    platform,
    content_type,
    COUNT(*) AS title_count
FROM ott_content
GROUP BY
    platform,
    content_type
ORDER BY
    platform,
    title_count DESC;
    
-- Yearly Content Trend
SELECT
    release_year,
    COUNT(*) AS title_count
FROM ott_content
WHERE release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year;

-- Platform Yearly Trend
SELECT
    release_year,
    platform,
    COUNT(*) AS title_count
FROM ott_content
WHERE release_year IS NOT NULL
GROUP BY
    release_year,
    platform
ORDER BY
    release_year,
    platform;
    
-- Platform Ranking
WITH platform_metrics AS (

    SELECT
        platform,

        COUNT(*) AS title_count,

        AVG(imdb_rating)
            AS average_rating,

        AVG(content_success_score)
            AS success_score

    FROM ott_content

    GROUP BY platform
)

SELECT
    platform,
    title_count,

    ROUND(
        average_rating,
        2
    ) AS average_rating,

    ROUND(
        success_score,
        2
    ) AS success_score,

    RANK() OVER (
        ORDER BY average_rating DESC
    ) AS rating_rank,

    RANK() OVER (
        ORDER BY title_count DESC
    ) AS catalog_rank,

    RANK() OVER (
        ORDER BY success_score DESC
    ) AS success_rank

FROM platform_metrics;

SELECT
    platform,
    COUNT(*) AS total_titles,
    ROUND(AVG(imdb_rating), 2) AS average_rating,
    ROUND(AVG(imdb_votes), 0) AS average_votes
FROM ott_content
GROUP BY platform
ORDER BY average_rating DESC;