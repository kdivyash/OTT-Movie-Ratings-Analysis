CREATE DATABASE ott_movie_analysis;

USE ott_movie_analysis;

SELECT DATABASE();

CREATE TABLE ott_content (
    id INT AUTO_INCREMENT PRIMARY KEY,
    platform VARCHAR(100),
    title VARCHAR(500),
    content_type VARCHAR(50),
    release_year INT,
    age_rating VARCHAR(50),
    genres TEXT,
    country TEXT,
    imdb_rating DECIMAL(3,1),
    imdb_votes BIGINT,
    content_success_score DECIMAL(6,2)
);

SHOW TABLES;

DESCRIBE ott_content;

-- Verify the Data
SELECT COUNT(*) AS total_records
FROM ott_content;

-- Check the actual data
SELECT *
FROM ott_content
LIMIT 10;

-- Check Platform Counts
 SELECT
    platform,
    COUNT(*) AS total_titles
FROM ott_content
GROUP BY platform
ORDER BY total_titles DESC;

-- Check Rating Data
SELECT
    MIN(imdb_rating) AS minimum_rating,
    MAX(imdb_rating) AS maximum_rating,
    ROUND(AVG(imdb_rating), 2) AS average_rating
FROM ott_content;

-- Check Missing Values (This is an important Data Analyst step.)
SELECT
    COUNT(*) AS total_records,
    SUM(platform IS NULL) AS missing_platform,
    SUM(title IS NULL) AS missing_title,
    SUM(release_year IS NULL) AS missing_year,
    SUM(imdb_rating IS NULL) AS missing_rating,
    SUM(imdb_votes IS NULL) AS missing_votes
FROM ott_content;


-- Backup Your Existing Table
USE ott_movie_analysis;

CREATE TABLE ott_content_backup AS
SELECT *
FROM ott_content;

SELECT COUNT(*) AS backup_records
FROM ott_content_backup;