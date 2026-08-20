USE ott_movie_analysis;

CREATE TABLE platforms (
    platform_id INT AUTO_INCREMENT PRIMARY KEY,
    platform_name VARCHAR(100) NOT NULL UNIQUE
);

DESCRIBE platforms;

-- Populate Platforms
INSERT INTO platforms (platform_name)
SELECT DISTINCT platform
FROM ott_content
WHERE platform IS NOT NULL;

SELECT *
FROM platforms;

-- Titles Table
CREATE TABLE titles (
    title_id INT AUTO_INCREMENT PRIMARY KEY,

    platform_id INT NOT NULL,

    title VARCHAR(500) NOT NULL,

    content_type VARCHAR(50),

    release_year INT,

    age_rating VARCHAR(50),

    country TEXT,

    imdb_rating DECIMAL(3,1),

    imdb_votes BIGINT,

    content_success_score DECIMAL(6,2),

    FOREIGN KEY (platform_id)
        REFERENCES platforms(platform_id)
);

-- 
DESCRIBE titles;

-- Populate the Titles Table
INSERT INTO titles (
    platform_id,
    title,
    content_type,
    release_year,
    age_rating,
    country,
    imdb_rating,
    imdb_votes,
    content_success_score
)
SELECT
    p.platform_id,
    o.title,
    o.content_type,
    o.release_year,
    o.age_rating,
    o.country,
    o.imdb_rating,
    o.imdb_votes,
    o.content_success_score

FROM ott_content o

JOIN platforms p
    ON o.platform = p.platform_name;

-- Verify    
SELECT COUNT(*) AS total_titles
FROM titles;

SELECT *
FROM titles
LIMIT 10;

-- Verify Platform Relationship
SELECT
    t.title_id,
    t.title,
    p.platform_name,
    t.imdb_rating

FROM titles t

JOIN platforms p
    ON t.platform_id = p.platform_id

LIMIT 20;

-- Genres Table
CREATE TABLE genres (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,

    genre_name VARCHAR(100) NOT NULL UNIQUE
);

DESCRIBE genres;

-- Create Title-Genre Relationship Table
CREATE TABLE title_genres (
    title_id INT NOT NULL,
    genre_id INT NOT NULL,

    PRIMARY KEY (
        title_id,
        genre_id
    ),

    FOREIGN KEY (
        title_id
    )
    REFERENCES titles(title_id),

    FOREIGN KEY (
        genre_id
    )
    REFERENCES genres(genre_id)
);

USE ott_movie_analysis;

SELECT COUNT(*) AS current_genres
FROM genres;

INSERT INTO genres (genre_name)
VALUES
('Action'),
('Action & Adventure'),
('Action-Adventure'),
('Adventure'),
('Animals & Nature'),
('Animation'),
('Anime'),
('Anime Features'),
('Anime Series'),
('Anthology'),
('Arthouse'),
('Arts'),
('Biographical'),
('British TV Shows'),
('Buddy'),
('Children & Family Movies'),
('Classic & Cult TV'),
('Classic Movies'),
('Comedies'),
('Comedy'),
('Coming of Age'),
('Concert Film'),
('Crime'),
('Crime TV Shows'),
('Cult Movies'),
('Dance'),
('Disaster'),
('Documentaries'),
('Documentary'),
('Docuseries'),
('Drama'),
('Dramas'),
('Entertainment'),
('Faith & Spirituality'),
('Faith and Spirituality'),
('Family'),
('Fantasy'),
('Game Show / Competition'),
('Historical'),
('Horror'),
('Horror Movies'),
('Independent Movies'),
('International'),
('International Movies'),
('International TV Shows'),
('Kids'),
('Kids'' TV'),
('Korean TV Shows'),
('LGBTQ'),
('LGBTQ Movies'),
('Lifestyle'),
('Medical'),
('Military and War'),
('Movies'),
('Music'),
('Music & Musicals'),
('Music Videos and Concerts'),
('Musical'),
('Mystery'),
('Parody'),
('Reality'),
('Reality TV'),
('Romance'),
('Romantic Comedy'),
('Romantic Movies'),
('Romantic TV Shows'),
('Sci-Fi & Fantasy'),
('Science & Nature TV'),
('Science Fiction'),
('Soap Opera / Melodrama'),
('Spanish-Language TV Shows'),
('Special Interest'),
('Sports'),
('Sports Movies'),
('Spy/Espionage'),
('Stand-Up Comedy'),
('Stand-Up Comedy & Talk Shows'),
('Superhero'),
('Survival'),
('Suspense'),
('TV Action & Adventure'),
('TV Comedies'),
('TV Dramas'),
('TV Horror'),
('TV Mysteries'),
('TV Sci-Fi & Fantasy'),
('TV Shows'),
('TV Thrillers'),
('Talk Show'),
('Talk Show and Variety'),
('Teen TV Shows'),
('Thriller'),
('Thrillers'),
('Travel'),
('Unscripted'),
('Western'),
('Young Adult Audience'),
('and Culture');

SELECT COUNT(*) AS total_genres
FROM genres;

SELECT *
FROM genres
ORDER BY genre_id;

CREATE TABLE genre_staging (
    title VARCHAR(500),
    genre_name VARCHAR(100),
    platform VARCHAR(100)
);

DESCRIBE genre_staging;

SELECT
    genre_name,
    COUNT(*) AS occurrences
FROM genres
GROUP BY genre_name
HAVING COUNT(*) > 1;

DESCRIBE genre_staging;

SHOW TABLES;

SELECT COUNT(*) AS current_relationships
FROM title_genres;

--
SELECT COUNT(*) AS staging_records
FROM genre_staging;

SELECT *
FROM genre_staging
LIMIT 20;

-- 
SELECT DISTINCT
    s.platform
FROM genre_staging s
LEFT JOIN platforms p
    ON s.platform = p.platform_name
WHERE p.platform_id IS NULL;

--
SELECT DISTINCT
    s.genre_name
FROM genre_staging s
LEFT JOIN genres g
    ON s.genre_name = g.genre_name
WHERE g.genre_id IS NULL;

--
SELECT
    s.platform,
    s.title
FROM genre_staging s
LEFT JOIN platforms p
    ON s.platform = p.platform_name
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title = s.title
WHERE t.title_id IS NULL
LIMIT 30;

--
SELECT
    s.platform,
    s.title
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND TRIM(t.title) = TRIM(s.title)
WHERE t.title_id IS NULL
LIMIT 30;

--
SELECT DISTINCT
    s.platform
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
WHERE p.platform_id IS NULL;

--
SELECT
    s.platform,
    s.title,
    t.title_id,
    t.title AS matched_title
FROM genre_staging s
JOIN titles t
    ON TRIM(s.title) = TRIM(t.title)
WHERE NOT EXISTS (
    SELECT 1
    FROM titles t2
    JOIN platforms p2
        ON t2.platform_id = p2.platform_id
    WHERE TRIM(t2.title) = TRIM(s.title)
      AND TRIM(p2.platform_name) = TRIM(s.platform)
)
LIMIT 30;

--
SELECT
    t.title_id,
    t.title,
    p.platform_name
FROM titles t
JOIN platforms p
    ON t.platform_id = p.platform_id
WHERE t.title LIKE '%Legend of Exorcism%';

SELECT
    s.platform,
    CONCAT('[', s.title, ']') AS staging_title,
    LENGTH(s.title) AS staging_length
FROM genre_staging s
WHERE s.title IS NOT NULL
LIMIT 20;

--
SELECT
    COUNT(*) AS total_staging_rows,

    SUM(
        CASE
            WHEN t.title_id IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS matched_rows,

    SUM(
        CASE
            WHEN t.title_id IS NULL
            THEN 1
            ELSE 0
        END
    ) AS unmatched_rows

FROM genre_staging s

LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)

LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND TRIM(t.title) = TRIM(s.title);
    
--
SELECT
    s.platform,
    s.title
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND TRIM(t.title) = TRIM(s.title)
WHERE t.title_id IS NULL
LIMIT 30;

--
SELECT
    COUNT(*) AS total_staging_rows,
    SUM(CASE WHEN t.title_id IS NOT NULL THEN 1 ELSE 0 END) AS matched_rows,
    SUM(CASE WHEN t.title_id IS NULL THEN 1 ELSE 0 END) AS unmatched_rows
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND TRIM(t.title) = TRIM(s.title);
    
-- 
SELECT
    title_id,
    title,
    platform_id
FROM titles
WHERE title LIKE '%Darwin%Game%';

--
SELECT
    title_id,
    title,
    platform_id
FROM titles
WHERE title LIKE '%Private Network%'
   OR title LIKE '%Legend%Exorcism%'
   OR title LIKE '%Elite Short Stories%'
   OR title LIKE '%Dügün%'
   OR title LIKE '%Hayat%'
   OR title LIKE '%Niyazi%'
   OR title LIKE '%Garth Brooks%'
   OR title LIKE '%Ni de coña%'
   OR title LIKE '%Çarsi Pazar%'
   OR title LIKE '%El final del paraíso%'
   OR title LIKE '%Pelé%';
   
--
ALTER TABLE titles
ADD COLUMN title_match_key VARCHAR(500);

ALTER TABLE genre_staging
ADD COLUMN title_match_key VARCHAR(500);

UPDATE titles
SET title_match_key =
    LOWER(
        TRIM(
            REPLACE(
                REPLACE(
                    REPLACE(
                        title,
                        '’',
                        ''''
                    ),
                    '‘',
                    ''''
                ),
                CONVERT(0xC2A0 USING utf8mb4),
                ' '
            )
        )
    );

SET SQL_SAFE_UPDATES = 0;

--
SELECT
    title_id,
    title,
    title_match_key
FROM titles
LIMIT 20;

--
UPDATE genre_staging
SET title_match_key =
    LOWER(
        TRIM(
            REPLACE(
                REPLACE(
                    REPLACE(
                        title,
                        '’',
                        ''''
                    ),
                    '‘',
                    ''''
                ),
                CONVERT(0xC2A0 USING utf8mb4),
                ' '
            )
        )
    );
    
SET SQL_SAFE_UPDATES = 1;

--
SELECT
    s.title AS staging_title,
    t.title AS database_title,
    s.title_match_key,
    t.title_match_key
FROM genre_staging s
JOIN titles t
    ON s.title_match_key = t.title_match_key
WHERE s.title LIKE '%Darwin%Game%'
LIMIT 10;

SELECT
    s.platform,
    s.title
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title_match_key = s.title_match_key
WHERE t.title_id IS NULL
LIMIT 30;

--
SELECT
    title,
    COUNT(*) AS records
FROM genre_staging
WHERE title IN (
    'Darwin’s Game',
    'Private Network: Who Killed Manuel Buendía?',
    'Legend of Exorcism',
    'Elite Short Stories: Nadia Guzmán',
    'Elite Short Stories: Guzmán Caye Rebe',
    'Dügün Dernek 2: Sünnet',
    'Hayat Öpücügü',
    'Niyazi Gül Dörtnala',
    'Garth Brooks: The Road I’m On',
    'Ni de coña',
    'Çarsi Pazar',
    'El final del paraíso',
    'Pelé'
)
GROUP BY title;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM genre_staging
WHERE title IN (
    'Darwin’s Game',
    'Private Network: Who Killed Manuel Buendía?',
    'Legend of Exorcism',
    'Elite Short Stories: Nadia Guzmán',
    'Elite Short Stories: Guzmán Caye Rebe',
    'Dügün Dernek 2: Sünnet',
    'Hayat Öpücügü',
    'Niyazi Gül Dörtnala',
    'Garth Brooks: The Road I’m On',
    'Ni de coña',
    'Çarsi Pazar',
    'El final del paraíso',
    'Pelé'
);

SET SQL_SAFE_UPDATES = 1;

--
SELECT
    title,
    COUNT(*) AS records
FROM genre_staging
WHERE title IN (
    'Darwin’s Game',
    'Private Network: Who Killed Manuel Buendía?',
    'Legend of Exorcism',
    'Elite Short Stories: Nadia Guzmán',
    'Elite Short Stories: Guzmán Caye Rebe',
    'Dügün Dernek 2: Sünnet',
    'Hayat Öpücügü',
    'Niyazi Gül Dörtnala',
    'Garth Brooks: The Road I’m On',
    'Ni de coña',
    'Çarsi Pazar',
    'El final del paraíso',
    'Pelé'
)
GROUP BY title;

--
SELECT
    title_id,
    title,
    platform_id
FROM titles
WHERE title IN (
    'Darwin’s Game',
    'Private Network: Who Killed Manuel Buendía?',
    'Legend of Exorcism',
    'Elite Short Stories: Nadia Guzmán',
    'Elite Short Stories: Guzmán Caye Rebe',
    'Dügün Dernek 2: Sünnet',
    'Hayat Öpücügü',
    'Niyazi Gül Dörtnala',
    'Garth Brooks: The Road I’m On',
    'Ni de coña',
    'Çarsi Pazar',
    'El final del paraíso',
    'Pelé'
);

--
SELECT
    s.platform,
    s.title
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title_match_key = s.title_match_key
WHERE t.title_id IS NULL
LIMIT 300;

--
USE ott_movie_analysis;

CREATE TABLE IF NOT EXISTS excluded_titles (
    exclusion_id INT AUTO_INCREMENT PRIMARY KEY,
    platform VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    reason VARCHAR(255) NOT NULL,
    excluded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DESCRIBE excluded_titles;

SELECT DISTINCT
    s.platform,
    s.title
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title_match_key = s.title_match_key
WHERE t.title_id IS NULL
ORDER BY s.platform, s.title;

--
SELECT COUNT(*) AS unmatched_titles
FROM (
    SELECT DISTINCT
        s.platform,
        s.title
    FROM genre_staging s
    LEFT JOIN platforms p
        ON TRIM(s.platform) = TRIM(p.platform_name)
    LEFT JOIN titles t
        ON t.platform_id = p.platform_id
        AND t.title_match_key = s.title_match_key
    WHERE t.title_id IS NULL
) AS unmatched;


--
INSERT INTO excluded_titles (
    platform,
    title,
    reason
)
SELECT DISTINCT
    s.platform,
    s.title,
    'Title not found in normalized titles table'
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title_match_key = s.title_match_key
WHERE t.title_id IS NULL;

--
SELECT
    exclusion_id,
    platform,
    title,
    reason,
    excluded_at
FROM excluded_titles
ORDER BY exclusion_id;

SET SQL_SAFE_UPDATES = 0;

DELETE s
FROM genre_staging s
JOIN excluded_titles e
    ON s.platform = e.platform
    AND s.title = e.title;
    
SET SQL_SAFE_UPDATES = 1;

--
SELECT DISTINCT
    s.platform,
    s.title
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title_match_key = s.title_match_key
WHERE t.title_id IS NULL
LIMIT 30;

SELECT COUNT(*) AS remaining_staging_records
FROM genre_staging;

SELECT COUNT(*) AS excluded_titles
FROM excluded_titles;

--
SELECT DISTINCT
    s.platform,
    s.title
FROM genre_staging s
LEFT JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)
LEFT JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title_match_key = s.title_match_key
WHERE t.title_id IS NULL;

--
SELECT DISTINCT
    s.genre_name
FROM genre_staging s
LEFT JOIN genres g
    ON s.genre_name = g.genre_name
WHERE g.genre_id IS NULL;

USE ott_movie_analysis;

SELECT COUNT(*) AS existing_relationships
FROM title_genres;

-- 
SELECT DISTINCT
    t.title_id,
    g.genre_id,
    t.title,
    p.platform_name,
    g.genre_name
FROM genre_staging s

JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)

JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title_match_key = s.title_match_key

JOIN genres g
    ON s.genre_name = g.genre_name

LIMIT 30;

--
SELECT COUNT(*) AS relationships_to_insert
FROM (
    SELECT DISTINCT
        t.title_id,
        g.genre_id
    FROM genre_staging s

    JOIN platforms p
        ON TRIM(s.platform) = TRIM(p.platform_name)

    JOIN titles t
        ON t.platform_id = p.platform_id
        AND t.title_match_key = s.title_match_key

    JOIN genres g
        ON s.genre_name = g.genre_name
) AS relationship_data;

--
INSERT IGNORE INTO title_genres (
    title_id,
    genre_id
)
SELECT DISTINCT
    t.title_id,
    g.genre_id
FROM genre_staging s

JOIN platforms p
    ON TRIM(s.platform) = TRIM(p.platform_name)

JOIN titles t
    ON t.platform_id = p.platform_id
    AND t.title_match_key = s.title_match_key

JOIN genres g
    ON s.genre_name = g.genre_name;
    
SELECT COUNT(*) AS total_relationships
FROM title_genres;

--
SELECT
    tg.title_id,
    tg.genre_id,
    t.title,
    p.platform_name,
    g.genre_name,
    t.imdb_rating
FROM title_genres tg

JOIN titles t
    ON tg.title_id = t.title_id

JOIN platforms p
    ON t.platform_id = p.platform_id

JOIN genres g
    ON tg.genre_id = g.genre_id

ORDER BY tg.title_id

LIMIT 30;

--
SELECT
    p.platform_name,
    COUNT(DISTINCT t.title_id) AS titles,
    COUNT(DISTINCT tg.genre_id) AS genres,
    COUNT(*) AS genre_relationships
FROM title_genres tg

JOIN titles t
    ON tg.title_id = t.title_id

JOIN platforms p
    ON t.platform_id = p.platform_id

GROUP BY p.platform_name

ORDER BY titles DESC;

SELECT COUNT(*) AS total_relationships
FROM title_genres;

SELECT
    title_id,
    genre_id,
    COUNT(*) AS duplicate_count
FROM title_genres
GROUP BY title_id, genre_id
HAVING COUNT(*) > 1;

--
SELECT
    tg.title_id,
    tg.genre_id,
    t.title,
    p.platform_name,
    g.genre_name,
    t.imdb_rating
FROM title_genres tg
JOIN titles t
    ON tg.title_id = t.title_id
JOIN platforms p
    ON t.platform_id = p.platform_id
JOIN genres g
    ON tg.genre_id = g.genre_id
ORDER BY tg.title_id
LIMIT 30;

-- Genre Distribution
SELECT
    g.genre_name,
    COUNT(DISTINCT tg.title_id) AS title_count
FROM title_genres tg
JOIN genres g
    ON tg.genre_id = g.genre_id
GROUP BY g.genre_name
ORDER BY title_count DESC
LIMIT 20;

-- Average IMDb Rating by Genre
SELECT
    g.genre_name,
    COUNT(DISTINCT t.title_id) AS title_count,
    ROUND(AVG(t.imdb_rating), 2) AS average_rating
FROM title_genres tg
JOIN titles t
    ON tg.title_id = t.title_id
JOIN genres g
    ON tg.genre_id = g.genre_id
WHERE t.imdb_rating IS NOT NULL
GROUP BY g.genre_name
HAVING COUNT(DISTINCT t.title_id) >= 20
ORDER BY average_rating DESC;

-- Platform × Genre Analysis
SELECT
    p.platform_name,
    g.genre_name,
    COUNT(DISTINCT t.title_id) AS title_count,
    ROUND(AVG(t.imdb_rating), 2) AS average_rating
FROM title_genres tg
JOIN titles t
    ON tg.title_id = t.title_id
JOIN platforms p
    ON t.platform_id = p.platform_id
JOIN genres g
    ON tg.genre_id = g.genre_id
WHERE t.imdb_rating IS NOT NULL
GROUP BY
    p.platform_name,
    g.genre_name
HAVING COUNT(DISTINCT t.title_id) >= 20
ORDER BY
    p.platform_name,
    average_rating DESC;
    
-- Best Genre per Platform
WITH genre_platform AS (

    SELECT
        p.platform_name,
        g.genre_name,
        COUNT(DISTINCT t.title_id) AS title_count,
        AVG(t.imdb_rating) AS average_rating

    FROM title_genres tg

    JOIN titles t
        ON tg.title_id = t.title_id

    JOIN platforms p
        ON t.platform_id = p.platform_id

    JOIN genres g
        ON tg.genre_id = g.genre_id

    WHERE t.imdb_rating IS NOT NULL

    GROUP BY
        p.platform_name,
        g.genre_name

    HAVING COUNT(DISTINCT t.title_id) >= 20
),

ranked_genres AS (

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
    ROUND(average_rating, 2) AS average_rating
FROM ranked_genres
WHERE genre_rank = 1
ORDER BY platform_name;

-- Check Normalization Integrity
SELECT
    COUNT(*) AS total_titles
FROM titles;

SELECT
    COUNT(*) AS titles_with_genres
FROM titles t
WHERE EXISTS (
    SELECT 1
    FROM title_genres tg
    WHERE tg.title_id = t.title_id
);

SELECT
    COUNT(*) AS titles_without_genres
FROM titles t
WHERE NOT EXISTS (
    SELECT 1
    FROM title_genres tg
    WHERE tg.title_id = t.title_id
);