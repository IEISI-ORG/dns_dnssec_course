-- Run after prep-1/prep-2 for every team: ages oldNN.example past the 5-day
-- add grace period so that a delete puts it into the redemption period.
USE registry;
UPDATE domain SET crdate = crdate - INTERVAL 10 DAY, rgpstatus = NULL, addPeriod = NULL
 WHERE name LIKE 'old%.example';
SELECT name, crdate, rgpstatus FROM domain WHERE name LIKE 'old%.example';
