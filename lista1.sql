--1.)
SELECT 
    imie_wroga WROG, 
    opis_incydentu PRZEWINA 
FROM
    Wrogowie_Kocurow 
WHERE 
    data_incydentu LIKE '2009%';

--2.)
SELECT 
    imie,
    funkcja,
    w_stadku_od "Z NAMI OD"
FROM
    Kocury
WHERE
    plec = 'D' AND
    w_stadku_od >= '2005-09-01' AND
    w_stadku_od <= '2007-07-31';

--3.)
SELECT 
    imie_wroga WROG, 
    gatunek,
    stopien_wrogosci "STOPIEN WROGOSCI"
FROM
    Wrogowie 
WHERE 
    lapowka IS NULL
ORDER BY 
    stopien_wrogosci;

--4.)
SELECT
    imie || ' zwany ' || pseudo || ' (fun. ' || funkcja || ') lowi myszki w bandzie ' || nr_bandy || ' od ' || w_stadku_od "WSZYSTKO O KOCURACH"
FROM
    Kocury
WHERE
    plec = 'M'
ORDER BY
    w_stadku_od DESC,
    pseudo ASC;

--5.)
SELECT
    pseudo,
    REGEXP_REPLACE(REGEXP_REPLACE(pseudo,'A','#',1,1), 'L', '%', 1, 1) "Po wymianie A na # oraz L na #"
FROM
    Kocury
WHERE
    pseudo LIKE '%L%' AND
    pseudo LIKE '%A%';
 
--6.)
SELECT
    imie,
    w_stadku_od "W stadku",
    CEIL(przydzial_myszy * 0.9) "Zjadal",
    ADD_MONTHS(w_stadku_od, 6) "Podwyzka",
    przydzial_myszy "Zjada"
FROM
    Kocury
WHERE
    months_between(date '2021-07-05', w_stadku_od) >= (12 * 12) AND 
    EXTRACT(MONTH from w_stadku_od) BETWEEN 3 AND 9;
    
--7.)
SELECT
    imie,
    przydzial_myszy * 3 "MYSZY KWARTALNIE",
    NVL(myszy_extra, 0) * 3 "KWARTALNE DODATKI"
FROM
    Kocury
WHERE
    przydzial_myszy > 2 * NVL(myszy_extra, 0) AND
    przydzial_myszy >= 55
ORDER BY
    przydzial_myszy DESC;

--8.)
SELECT 
    imie,
    CASE
        WHEN (przydzial_myszy + NVL(myszy_extra, 0)) * 12 = 660 THEN 'Limit' 
        WHEN (przydzial_myszy + NVL(myszy_extra, 0)) * 12 < 660 THEN 'Ponizej 660'
        ELSE TO_CHAR((przydzial_myszy + NVL(myszy_extra, 0)) * 12)
    END "Zjada rocznie"
FROM
    Kocury;

--9.) 
SELECT
    pseudo,
    w_stadku_od "W STADKU",
    CASE
        WHEN 
            EXTRACT(DAY FROM w_stadku_od) <= 15 AND 
            last_day('2021-10-26') - mod(to_char(last_day('2021-10-26'),'d')+3,7) > '2021-10-26' 
        THEN last_day('2021-10-26') - mod(to_char(last_day('2021-10-26'),'d')+3,7)
        ELSE last_day(add_months('2021-10-26', 1)) - mod(to_char(last_day(add_months('2021-10-26', 1)),'d')+3,7)
    END WYPLATA
FROM
    Kocury;
    
SELECT
    pseudo,
    w_stadku_od "W STADKU",
    CASE
        WHEN 
            EXTRACT(DAY FROM w_stadku_od) <= 15 AND 
            last_day('2021-10-28') - mod(to_char(last_day('2021-10-28'),'d')+3,7) > '2021-10-28' 
        THEN last_day('2021-10-28') - mod(to_char(last_day('2021-10-28'),'d')+3,7)
        ELSE last_day(add_months('2021-10-28', 1)) - mod(to_char(last_day(add_months('2021-10-28', 1)),'d')+3,7)
    END WYPLATA
FROM
    Kocury;

--10.)
SELECT
    pseudo || ' - ' ||
    CASE COUNT(*)
        WHEN 1 THEN 'Unikalny'
        ELSE 'nieunikalny'
    END "Unikalnosc atr. PSEUDO"
FROM
    Kocury
WHERE
    pseudo IS NOT NULL
GROUP BY
    pseudo;

SELECT
    szef || ' - ' ||
    CASE COUNT(*)
        WHEN 1 THEN 'Unikalny'
        ELSE 'nieunikalny'
    END "Unikalnosc atr. SZEF"
FROM
    Kocury
WHERE
    szef IS NOT NULL
GROUP BY
    szef;    

--11.) 
SELECT
    pseudo "Pseudonim",
    Count(*) "Liczba wrogow"
FROM   
    Wrogowie_Kocurow
GROUP BY
    pseudo
Having
    Count(*) >= 2;

--12.)
SELECT 
    'Liczba kotów= ' ||
    Count(*) ||
    ' lowi jako ' ||
    funkcja ||
    ' i zjada max. ' ||
    MAX(przydzial_myszy + NVL(myszy_extra, 0)) ||
    ' myszy miesiecznie' " "
FROM
    Kocury
WHERE
    plec != 'M' AND
    funkcja != 'SZEFUNIO'
GROUP BY
    funkcja
HAVING
    AVG(przydzial_myszy + NVL(myszy_extra, 0)) > 50;

--13.)
SELECT
    nr_bandy "Nr bandy",
    plec,
    MIN(przydzial_myszy) "Minimalny przydzial"
FROM 
    Kocury
GROUP BY
    nr_bandy,
    plec;

--14.)
SELECT
    level,
    pseudo,
    funkcja,
    nr_bandy
FROM 
    Kocury
WHERE plec = 'M'
CONNECT BY PRIOR pseudo=szef
START WITH funkcja = 'BANDZIOR';

--15.)
SELECT 
    lpad(level-1, (4 * (level-1))+1, '===>') || '           ' || imie "Hierarhia",
    NVL(szef, 'Sam sobie panem') "Pseudo szefa",
    funkcja "Funkcja"
FROM
    Kocury
WHERE
    myszy_extra IS NOT NULL
CONNECT BY PRIOR pseudo=szef
START WITH szef IS NULL;

--16.)
SELECT
    lpad(regexp_substr(SYS_CONNECT_BY_PATH(pseudo,','), '[^,]+', 2), LENGTH(regexp_substr(SYS_CONNECT_BY_PATH(pseudo,','), '[^,]+', 2)) + (4*(level-1))) "Droga sluzbowa"
FROM
    Kocury
WHERE
    plec = 'M' AND
    months_between(date '2021-07-05', w_stadku_od) >= (12 * 12) AND
    myszy_extra IS NULL
CONNECT BY PRIOR pseudo=szef
ORDER BY pseudo, level;
