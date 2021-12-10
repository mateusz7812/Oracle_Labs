
alter session set NLS_DATE_FORMAT = 'YYYY-MM-DD';

--17
SELECT
    K.pseudo "POLUJE W POLU",
    K.przydzial_myszy "PRZYDZIAL MYSZY",
    B.nazwa "BANDA"
FROM 
    Kocury K
INNER JOIN 
    Bandy B ON 
        K.nr_bandy = B.nr_bandy AND 
        B.teren IN ('POLE', 'CALOSC')
WHERE
    K.przydzial_myszy > 50;
    
--18
SELECT
    K.imie,
    K.w_stadku_od "POLUJE OD"
FROM Kocury K
INNER JOIN Kocury K2 ON K2.imie = 'JACEK' AND K.w_stadku_od < K2.w_stadku_od
ORDER BY K.w_stadku_od DESC;

--19a
SELECT
    K.imie "Imie",
    '|' " ",
    K.funkcja "Funkcja",
    '|' " ",
    K1.imie "Szef 1",
    '|' " ",
    NVL(K2.imie, ' ') "Szef 2",
    '|' " ",
    NVL(K3.imie, ' ') "Szef 3"
FROM 
    Kocury K
INNER JOIN Kocury K1 ON K.szef = K1.pseudo AND K.funkcja IN ('KOT', 'MILUSIA')
LEFT JOIN Kocury K2 ON K1.szef = K2.pseudo
LEFT JOIN Kocury K3 ON K2.szef = K3.pseudo;

--19b
SELECT 
    MAX("IMIE1") "Imie",
    '|' " ",
    MAX(root_function) "Funkcja",
    '|' "  ",
    NVL(MAX("SZEF1"), ' ') "Szef 1",
    '|' "   ",
    NVL(MAX("SZEF2"), ' ') "Szef 2",
    '|' "    ",
    NVL(MAX("SZEF3"), ' ') "Szef 3"
FROM
(
    SELECT
        imie,
        level lvl,
        connect_by_root pseudo as root_id,
        connect_by_root funkcja as root_function
    FROM 
        Kocury
    CONNECT BY 
        PRIOR szef = pseudo
    START WITH 
        funkcja IN ('KOT', 'MILUSIA')
)
PIVOT
(
    MAX(imie)
    FOR lvl
    IN (1 AS "IMIE1",
        2 AS "SZEF1",
        3 AS "SZEF2",
        4 AS "SZEF3")
)
GROUP BY 
    root_id;

--19c
SELECT
    connect_by_root imie "Imie",
    connect_by_root funkcja "Funkcja",
    REGEXP_SUBSTR(LTRIM(SYS_CONNECT_BY_PATH(RPAD(' ' || imie, 12) ,'|'), '|'), '\| .*') "Imiona kolejnych szefów"
FROM 
    Kocury
WHERE 
    szef IS NULL
CONNECT BY 
    PRIOR szef = pseudo
START WITH 
    funkcja IN ('KOT', 'MILUSIA');
    
--20
SELECT
    K.imie "Imie kotki",
    B.nazwa "Nazwa bandy",
    WK.imie_wroga "Imie wroga",
    W.stopien_wrogosci "Ocena wroga",
    WK.data_incydentu "Data inc."
FROM
    Kocury K
INNER JOIN 
    Wrogowie_Kocurow WK ON 
        K.pseudo = WK.pseudo AND 
        K.plec = 'D' AND 
        WK.data_incydentu > '2007-01-01' 
INNER JOIN 
    Wrogowie W ON 
        WK.imie_wroga = W.imie_wroga
INNER JOIN 
    Bandy B ON 
        K.nr_bandy = B.nr_bandy;

--21
SELECT
    B.nazwa "Nazwa bandy",
    COUNT(DISTINCT K.pseudo) "Koty z wrogami"
FROM 
    Bandy B
INNER JOIN 
    Kocury K ON B.nr_bandy = K.nr_bandy
INNER JOIN 
    Wrogowie_Kocurow WK ON K.pseudo = WK.pseudo
GROUP BY 
    B.nazwa;
    
--22
SELECT
    MAX(K.funkcja),
    K.pseudo,
    COUNT(*)
FROM 
    Kocury K
INNER JOIN 
    Wrogowie_Kocurow WK ON K.pseudo = WK.pseudo
GROUP BY 
    K.pseudo
HAVING 
    COUNT(*) > 1;
    
--23

    SELECT 
        imie,
        (przydzial_myszy + myszy_extra) * 12 "DAWKA ROCZNA",
        'powyzej 864' "DAWKA"
    FROM 
        Kocury
    WHERE
        (przydzial_myszy + myszy_extra) * 12 > 864
UNION
    SELECT 
        imie,
        (przydzial_myszy + myszy_extra) * 12 "DAWKA ROCZNA",
        '864' "DAWKA"
    FROM 
        Kocury
    WHERE
        (przydzial_myszy + myszy_extra) * 12 = 864
UNION
    SELECT 
        imie,
        (przydzial_myszy + myszy_extra) * 12 "DAWKA ROCZNA",
        'ponizej 864' "DAWKA"
    FROM 
        Kocury
    WHERE
        (przydzial_myszy + myszy_extra) * 12 < 864   
ORDER BY
    2 DESC;
    
--24
SELECT
    B.nr_bandy "NR BANDY",
    B.nazwa,
    B.teren
FROM
    Bandy B
LEFT JOIN 
    Kocury K ON B.nr_bandy = K.nr_bandy
WHERE
    K.pseudo IS NULL;
    
    
SELECT
    B.nr_bandy "NR BANDY",
    B.nazwa,
    B.teren
FROM
    Bandy B
WHERE
    B.nr_bandy IN
    (
            SELECT
                nr_bandy
            FROM
                Bandy
        MINUS
            SELECT
                nr_bandy
            FROM 
                Kocury
            GROUP BY
                nr_bandy
    );
    
--25
SELECT
    imie, 
    funkcja,
    przydzial_myszy "PRZYDZIAL MYSZY"
FROM
    Kocury
WHERE
    przydzial_myszy >= 
    (
        SELECT
            3 * K.przydzial_myszy
        FROM Kocury K
        INNER JOIN 
            Bandy B ON K.nr_bandy = B.nr_bandy AND 
            B.TEREN IN ('SAD', 'CALOSC') AND 
            K.funkcja = 'MILUSIA'
        ORDER BY 
            K.przydzial_myszy DESC
        FETCH NEXT 1 ROW ONLY
    );
    
--26
SELECT
    funkcja,
    srednie "Srednio najw. i najm. myszy"
FROM
(
    SELECT
        funkcja,
        CEIL(AVG(przydzial_myszy + NVL(myszy_extra, 0))) srednie,
        row_number() over (order by CEIL(AVG(przydzial_myszy + NVL(myszy_extra, 0)))) as numer,
        count(*) over () as cnt
    FROM
        Kocury
    WHERE 
        funkcja <> 'SZEFUNIO'
    GROUP BY
        funkcja
)
WHERE
    numer = cnt OR numer = 1;
    
--27a
ACCEPT x NUMBER PROMPT 'Prosz? poda? warto?? dla n: ';

SELECT
    K.pseudo,
    K.przydzial_myszy + NVL(K.myszy_extra, 0) "ZJADA"
FROM
    Kocury K
WHERE
    (
        SELECT 
            COUNT(DISTINCT K2.przydzial_myszy + NVL(K2.myszy_extra, 0))
        FROM 
            Kocury K2 
        WHERE 
            K.przydzial_myszy + NVL(K.myszy_extra, 0) < K2.przydzial_myszy + NVL(K2.myszy_extra, 0)
    ) < &x
ORDER BY
    K.przydzial_myszy + NVL(K.myszy_extra, 0) DESC;

--27b
SELECT
    K.pseudo,
    K.przydzial_myszy + NVL(K.myszy_extra, 0)
FROM 
    Kocury K
WHERE
    K.przydzial_myszy + NVL(K.myszy_extra, 0) >=
(
    SELECT 
        MIN(zjada)
    FROM
    (
        SELECT DISTINCT
            K2.przydzial_myszy + NVL(K2.myszy_extra, 0) zjada
        FROM
            Kocury K2
        ORDER BY 
            K2.przydzial_myszy + NVL(K2.myszy_extra, 0) DESC
    )
    WHERE ROWNUM <= &x
);
    
--27c
SELECT
    K.pseudo pseudo,
    K.przydzial_myszy + NVL(K.myszy_extra, 0) zjada
FROM
    Kocury K
LEFT JOIN Kocury K2 ON 
    K.przydzial_myszy + NVL(K.myszy_extra, 0) < K2.przydzial_myszy + NVL(K2.myszy_extra, 0)
GROUP BY
    K.pseudo,
    K.przydzial_myszy + NVL(K.myszy_extra, 0)
HAVING
    COUNT(DISTINCT K2.przydzial_myszy + NVL(K2.myszy_extra, 0)) < &x
ORDER BY
    MAX(K.przydzial_myszy + NVL(K.myszy_extra, 0)) DESC;

--27d
SELECT 
    pseudo, 
    "ZJADA"
FROM(
    SELECT 
        pseudo,
        przydzial_myszy + NVL(myszy_extra, 0) "ZJADA",
        DENSE_RANK()
            OVER(ORDER BY przydzial_myszy + NVL(myszy_extra, 0) DESC) AS rank
    FROM
    Kocury
)
WHERE rank < (&x + 1);
    
--28
WITH counted as
(
    SELECT 
        TO_CHAR(EXTRACT(YEAR FROM w_stadku_od)) "ROK",
        COUNT(*) liczba
    FROM
        Kocury
    GROUP BY
        TO_CHAR(EXTRACT(YEAR FROM w_stadku_od))        
), average as (
    SELECT 
        AVG(COUNT(*)) average_val
    FROM Kocury
    GROUP BY EXTRACT(YEAR FROM w_stadku_od)
)
(
    SELECT
        "ROK",
        liczba "LICZBA WSTAPIEN"
    FROM
    (
        SELECT 
            "ROK", 
            liczba, 
            DENSE_RANK()
            OVER(ORDER BY liczba DESC) rank
        FROM
            counted, average
        WHERE liczba < average_val
    )
    WHERE rank = 1

) UNION (
    SELECT 'Srednia', ROUND(average_val, 7) FROM average  
) UNION (
    SELECT
        "ROK",
        liczba
    FROM
    (
        SELECT 
            "ROK", 
            liczba, 
            DENSE_RANK()
                OVER(ORDER BY liczba) rank
        FROM
        counted, average
        WHERE liczba > average_val
    )
    WHERE rank = 1
)
ORDER BY
    2;

--29a
SELECT 
    MAX(K.imie) imie,
    MAX(K.przydzial_myszy + NVL(K.myszy_extra, 0)) zjada,
    MAX(K.nr_bandy) nr_bandy,
    AVG(KB.przydzial_myszy + NVL(KB.myszy_extra, 0)) "SREDNIA BANDY"
FROM 
    Kocury K, 
    Kocury KB
WHERE
    K.nr_bandy = KB.nr_bandy AND
    K.plec = 'M'
GROUP BY
    K.pseudo
HAVING
    MAX(K.przydzial_myszy + NVL(K.myszy_extra, 0)) < 
    AVG(KB.przydzial_myszy + NVL(KB.myszy_extra, 0));


--29b
SELECT
    imie, 
    zjada,
    nr_bandy,
    srednia
FROM
(
    SELECT 
        MAX(K.imie) imie,
        MAX(K.przydzial_myszy + NVL(K.myszy_extra, 0)) zjada,
        MAX(K.nr_bandy) nr_bandy,
        AVG(KB.przydzial_myszy + NVL(KB.myszy_extra, 0)) srednia
    FROM 
        Kocury K, 
        Kocury KB
    WHERE
        K.nr_bandy = KB.nr_bandy AND
        K.plec = 'M'
    GROUP BY
        K.pseudo
)
WHERE
    zjada < srednia;

--29c
SELECT
    K.imie, 
    K.przydzial_myszy + NVL(K.myszy_extra, 0) zjada,
    K.nr_bandy "NR BANDY",
    (
        SELECT 
            AVG(KW.przydzial_myszy + NVL(KW.myszy_extra, 0)) 
        FROM 
            Kocury KW
        WHERE
            KW.nr_bandy = K.nr_bandy
    ) "SREDNIA BANDY"
FROM
    Kocury K
WHERE
    plec = 'M' AND 
    K.przydzial_myszy + NVL(K.myszy_extra, 0) < 
    (
        SELECT 
            AVG(KW.przydzial_myszy + NVL(KW.myszy_extra, 0)) 
        FROM 
            Kocury KW
        WHERE
            KW.nr_bandy = K.nr_bandy
    );

--30
WITH daty AS
(
    SELECT 
        nr_bandy,
        MAX(nazwa) nazwa,
        MAX(w_stadku_od) najmlodszy,
        MIN(w_stadku_od) najstarszy
    FROM 
        Kocury
    NATURAL JOIN 
        Bandy
    GROUP BY
        nr_bandy
)
(
    SELECT
        imie,
        w_stadku_od "WSTAPIL DO STADKA", 
        '<--- NAJMLODSZY STAZEM W BANDZIE ' || D.nazwa " "
    FROM 
        Kocury K
    INNER JOIN
        daty D ON K.nr_bandy = D.nr_bandy
    WHERE 
        K.w_stadku_od = D.najmlodszy
UNION
    SELECT
        imie,
        w_stadku_od,
        '<--- NAJSTARSZY STAZEM W BANDZIE ' || D.nazwa
    FROM 
        Kocury K
    INNER JOIN
        daty D ON K.nr_bandy = D.nr_bandy
    WHERE 
        K.w_stadku_od = D.najstarszy
UNION
    SELECT
        imie,
        w_stadku_od,
        ' '
    FROM 
        Kocury K
    INNER JOIN
        daty D ON K.nr_bandy = D.nr_bandy
    WHERE 
        NOT K.w_stadku_od = D.najstarszy AND
        NOT K.w_stadku_od = D.najmlodszy        
);

--31
CREATE OR REPLACE VIEW Spozycie_band (nazwa_bandy, sre_spoz, max_spoz, min_spoz, koty, koty_z_dod)
AS
(
    SELECT 
        B.nazwa,
        AVG(K.przydzial_myszy),
        MAX(K.przydzial_myszy),
        MiN(K.przydzial_myszy),
        COUNT(*),
        COUNT(K.myszy_extra)
    FROM 
        Bandy B
    INNER JOIN 
        Kocury K ON K.nr_bandy = B.nr_bandy
    GROUP BY
        B.nazwa
);

SELECT 
    * 
FROM 
    Spozycie_band;
    
SELECT
    K.pseudo "PSEUDONIM",
    K.imie,
    K.funkcja,
    K.przydzial_myszy + NVL(K.myszy_extra, 0) "ZJADA",
    'OD ' || S.min_spoz || ' DO ' || S.max_spoz "GRANICE SPOZYCIA",
    K.w_stadku_od "LOWI OD"
FROM
    Kocury K
INNER JOIN 
    Bandy B ON K.pseudo = '&pseudo' AND B.nr_bandy = K.nr_bandy
INNER JOIN 
    Spozycie_band S ON S.nazwa_bandy = B.nazwa;

--32
CREATE OR REPLACE VIEW Myszy_extra_band (numer_bandy, nazwa_bandy, sre_myszy_extra)
AS
(
    SELECT 
        MAX(B.nr_bandy),
        B.nazwa,
        AVG(NVL(K.myszy_extra, 0))
    FROM 
        Bandy B
    INNER JOIN 
        Kocury K ON K.nr_bandy = B.nr_bandy
    GROUP BY
        B.nazwa
);

SELECT 
    * 
FROM 
    Myszy_extra_band;

CREATE OR REPLACE VIEW  Staze_czlonkow_band (pseudo, rank_staz)
AS
(
    SELECT 
        pseudo,        
        RANK()
            OVER(PARTITION BY nr_bandy ORDER BY w_stadku_od) rank
    FROM 
        Kocury
);

SELECT 
    * 
FROM 
    Staze_czlonkow_band;
    
CREATE OR REPLACE VIEW  Myszy_kocurow(pseudo, plec, myszy, extra, sre_extra_bandy, min_myszy)
AS
(
    SELECT
        K.pseudo,
        K.plec,
        K.przydzial_myszy,
        K.myszy_extra,
        M.sre_myszy_extra,
        (SELECT MIN(przydzial_myszy) FROM Kocury)
    FROM
        Kocury K
    INNER JOIN 
        BANDY B ON B.nr_Bandy = K.nr_bandy AND (B.nazwa = 'CZARNI RYCERZE' OR B.nazwa = 'LACIACI MYSLIWI')
    INNER JOIN
        Staze_czlonkow_band S ON S.pseudo = K.pseudo AND S.rank_staz < 4
    INNER JOIN
        Myszy_extra_band M ON M.numer_bandy = K.nr_bandy
);

SELECT 
    * 
FROM 
    Myszy_kocurow;

SELECT
    pseudo "Pseudonim",
    plec "Plec",
    myszy "Myszy przed podw.",
    NVL(extra, 0) "Extra przed podw."
FROM
    Myszy_kocurow;

CREATE OR REPLACE VIEW  Myszy_kocurow_update(pseudo, plec, myszy, extra, sre_extra_bandy, min_myszy)
AS
(
    SELECT
        pseudo,
        plec,
        CASE plec
            WHEN 'D' THEN myszy + (0.1 * min_myszy)
            WHEN 'M' THEN myszy + 10
            END,
        FLOOR((NVL(extra, 0) + (0.15 * sre_extra_bandy))),
        sre_extra_bandy,
        min_myszy
    FROM
        Myszy_kocurow
);
    
SELECT 
    * 
FROM 
    Myszy_kocurow_update;

UPDATE 
    Kocury K
SET
    (przydzial_myszy, myszy_extra) = 
        (
            SELECT
                myszy,
                extra
            FROM 
                Myszy_kocurow_update M
            WHERE
                K.pseudo = M.pseudo
        )
WHERE EXISTS (
    SELECT 
        1
    FROM 
        Myszy_kocurow_update M
    WHERE 
        K.pseudo = M.pseudo );
        

SELECT
    pseudo "Pseudonim",
    plec "Plec",
    myszy "Myszy po podw.",
    NVL(extra, 0) "Extra po podw."
FROM
    Myszy_kocurow;
    
ROLLBACK;


--33a
CREATE OR REPLACE VIEW  Funkcje_bandy_kocurow AS
(
    SELECT
        K.pseudo,
        K.plec,
        B.nazwa as banda,
        K.funkcja,
        K.przydzial_myszy + NVL(K.myszy_extra, 0) myszy
    FROM
        Kocury K        
    INNER JOIN
        Bandy B ON B.nr_bandy = K.nr_bandy
);

SELECT 
    * 
FROM 
    Funkcje_bandy_kocurow;
    
    
CREATE OR REPLACE VIEW Suma_myszy_kocurow AS
SELECT 
    banda,
    CASE plec
        WHEN 'D' THEN 'Kotka'
        ELSE 'Kocur'
        END "PLEC",
    COUNT(*) ile,
    SUM(DECODE(funkcja, 'SZEFUNIO', myszy, 0)) "SZEFUNIO", 
    SUM(DECODE(funkcja, 'BANDZIOR', myszy, 0)) "BANDZIOR", 
    SUM(DECODE(funkcja, 'LOWCZY', myszy, 0)) "LOWCZY", 
    SUM(DECODE(funkcja, 'LAPACZ', myszy, 0)) "LAPACZ", 
    SUM(DECODE(funkcja, 'KOT', myszy, 0)) "KOT", 
    SUM(DECODE(funkcja, 'MILUSIA', myszy, 0)) "MILUSIA", 
    SUM(DECODE(funkcja, 'DZIELCZY', myszy, 0)) "DZIELCZY",
    SUM(myszy) "Suma"
FROM 
    Funkcje_bandy_kocurow
GROUP BY
    banda, plec
ORDER BY 
    banda, plec;

SELECT 
    * 
FROM 
    Suma_myszy_kocurow;
 
 
SELECT
    banda "NAZWA BANDY",
    "PLEC",
    "ILE",
    "SZEFUNIO", 
    "BANDZIOR", 
    "LOWCZY",  
    "LAPACZ",  
    "KOT",  
    "MILUSIA",  
    "DZIELCZY", 
    "Suma"
FROM
(
    (
    SELECT
        banda || "PLEC" id_grupy,
        CASE "PLEC" 
            WHEN 'Kocur' THEN banda 
            ELSE ' ' 
            END banda,
        "PLEC",
        TO_CHAR(ile) "ILE",
        "SZEFUNIO", 
        "BANDZIOR", 
        "LOWCZY",  
        "LAPACZ",  
        "KOT",  
        "MILUSIA",  
        "DZIELCZY", 
        "Suma"
    FROM Suma_myszy_kocurow
    )
    UNION
    (
    SELECT
        NULL,
        'SUMA',
        ' ',
        ' ',
        SUM("SZEFUNIO"), 
        SUM("BANDZIOR"), 
        SUM("LOWCZY"),  
        SUM("LAPACZ"),  
        SUM("KOT"),  
        SUM("MILUSIA"),  
        SUM("DZIELCZY"), 
        SUM("Suma")
    FROM
        Suma_myszy_kocurow
    )
);

--33b
SELECT 
    CASE to_grupa 
        WHEN 1 THEN 'Suma' 
        ELSE (
            CASE plec 
                WHEN 'D' THEN banda 
                ELSE ' ' 
                END
            )
        END "NAZWA BANDY",
    CASE to_grupa
        WHEN 1 THEN ' ' 
        ELSE (
            CASE plec 
                WHEN 'D' THEN 'Kotka' 
                ELSE 'Kocur' 
                END
            )
        END plec,
    ile,
    NVL("'SZEFUNIO'", 0) "SZEFUNIO", 
    NVL("'BANDZIOR'", 0) "BANDZIOR", 
    NVL("'LOWCZY'", 0) "LOWCZY", 
    NVL("'LAPACZ'", 0) "LAPACZ", 
    NVL("'KOT'", 0) "KOT", 
    NVL("'MILUSIA'", 0) "MILUSIA", 
    NVL("'DZIELCZY'", 0) "DZIELCZY", 
    "'Suma'" "Suma"
FROM (
    SELECT 
        CASE GROUPING(K.funkcja) 
            WHEN 1 THEN 'Suma' 
            ELSE K.funkcja 
            END funkcja,
        K.nr_bandy || K.plec id_grupy,
        CASE GROUPING(K.nr_bandy || K.plec) 
            WHEN 1 THEN ' ' 
            ELSE MAX(B.nazwa)  
            END banda, 
        CASE GROUPING(K.nr_bandy || K.plec) 
            WHEN 1 THEN ' ' 
            ELSE TO_CHAR(MAX((SELECT COUNT(*) FROM Kocury KI WHERE KI.nr_bandy = K.nr_bandy AND KI.plec = K.plec)))
            END ile,
        CASE GROUPING(K.nr_bandy || K.plec) 
            WHEN 1 THEN ' ' 
            ELSE MAX(K.plec)  
            END plec, 
        GROUPING(K.nr_bandy || K.plec) to_grupa, 
        SUM(K.przydzial_myszy + NVL(K.myszy_extra, 0)) myszy
    FROM
        Kocury K
    INNER JOIN 
        Bandy B ON B.nr_bandy = K.nr_bandy
    GROUP BY 
        CUBE(K.funkcja, K.nr_bandy || K.plec)
)
PIVOT
(  
  SUM(myszy) FOR funkcja IN ('BANDZIOR', 'DZIELCZY', 'KOT', 'LAPACZ', 'LOWCZY', 'MILUSIA', 'SZEFUNIO', 'Suma')  
)  
ORDER BY 
    id_grupy;



