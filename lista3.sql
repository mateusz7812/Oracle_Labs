
alter session set NLS_DATE_FORMAT = 'YYYY-MM-DD';

--34
DECLARE
    func Kocury.funkcja%TYPE:='&funkcja';
    cnt INTEGER;
BEGIN
    SELECT 
        COUNT(*) 
    INTO 
        cnt 
    FROM 
        Kocury 
    WHERE 
        funkcja=func;
    IF cnt > 0
        THEN DBMS_OUTPUT.PUT_LINE('Znaleziono ' || func);
        ELSE DBMS_OUTPUT.PUT_LINE('Nie znaleziono');
    END IF;
END;

--35
DECLARE
    pseudoKota Kocury.pseudo%TYPE := '&pseudo';
    przydzialKota Kocury.przydzial_myszy%TYPE;
    imieKota Kocury.imie%TYPE;
    miesiacPrzystapienia INTEGER;
    flaga BOOLEAN:=FALSE;
BEGIN
    SELECT 
        przydzial_myszy + NVL(myszy_extra, 0),
        imie,
        EXTRACT(MONTH FROM w_stadku_od)
    INTO
        przydzialKota,
        imieKota,
        miesiacPrzystapienia
    FROM
        Kocury
    WHERE 
        pseudo = pseudoKota;
    
    IF przydzialKota * 12 > 700
        THEN DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700');
        flaga:= TRUE;
    END IF;
    
    IF INSTR(imieKota, 'A') > 0
        THEN DBMS_OUTPUT.PUT_LINE('imie zawiera litere A');
        flaga:= TRUE;
    END IF;
    
    IF miesiacPRzystapienia = 5
        THEN DBMS_OUTPUT.PUT_LINE('maj jest miesiacem prystapienia do stada');
        flaga:= TRUE;
    END IF;
    
    IF flaga = FALSE
        THEN DBMS_OUTPUT.PUT_LINE('nie odpowiada kryteriom');
    END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND 
        THEN DBMS_OUTPUT.PUT_LINE('nie znaleziono kota o podany pseudonimie');
END;

--36
SET SERVEROUTPUT ON
DECLARE
    CURSOR kotyDoModyfikacji IS
        SELECT
            pseudo,
            imie,
            przydzial_myszy,
            max_myszy
        FROM
            Kocury
        NATURAL JOIN
            Funkcje
        ORDER BY
            przydzial_myszy
        FOR UPDATE OF przydzial_myszy;
    kdm kotyDoModyfikacji%ROWTYPE;
    MAX_CALKOWITY INTEGER := 1050;
    przydzialCalkowity INTEGER;
    ZMIANA FLOAT := 0.1;
    nowyPrzydzial Kocury.przydzial_myszy%TYPE;
    operacji INTEGER := 0;
BEGIN
    SELECT
        SUM(przydzial_myszy)
    INTO
        PrzydzialCalkowity
    FROM 
        Kocury;
    SAVEPOINT przedZwiekszeniemPrzydzialu;
    <<zewn>> LOOP 
        FOR kdm in kotyDoModyfikacji
        LOOP
            IF kdm.przydzial_myszy <> kdm.max_myszy
                THEN
                    nowyPrzydzial := (kdm.przydzial_myszy * (ZMIANA + 1));
                    IF nowyPrzydzial > kdm.max_myszy
                        THEN nowyPrzydzial := kdm.max_myszy;
                    END IF;
                    przydzialCalkowity := przydzialCalkowity - kdm.przydzial_myszy + nowyPrzydzial;
                    UPDATE 
                        Kocury 
                    SET 
                        przydzial_myszy = nowyPrzydzial
                    WHERE
                        CURRENT OF kotyDoModyfikacji;
                    operacji := operacji + 1;
            END IF;
            EXIT zewn WHEN przydzialCalkowity > MAX_CALKOWITY;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Calk. przydzial w stadku ' || przydzialCalkowity || '  Zmian - ' || operacji);
    FOR k IN REVERSE kotyDoModyfikacji
    LOOP
        DBMS_OUTPUT.PUT_LINE(k.imie || ' ' || k.przydzial_myszy);
    END LOOP;
    ROLLBACK TO SAVEPOINT przedZwiekszeniemPrzydzialu;
END;


--37
SET SERVEROUTPUT ON
DECLARE
    CURSOR koty(liczba NUMBER) IS
        SELECT
            pseudo,
            przydzial_myszy + NVL(myszy_extra, 0) zjada
        FROM
            Kocury
        ORDER BY
            przydzial_myszy + NVL(myszy_extra, 0) DESC
        FETCH FIRST liczba ROWS ONLY;
    len INTEGER := 5;
    nr NUMBER := 1;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Nr Pseudonim  Zjada');
    DBMS_OUTPUT.PUT_LINE('-------------------');
    FOR k in koty(len)
    LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(nr, 3 - LENGTH(nr)) || ' ' || k.pseudo || LPAD(k.zjada, 15 - LENGTH(k.pseudo)));
        nr := nr + 1;
    END LOOP;
END;


--38
SET SERVEROUTPUT ON
DECLARE
    CURSOR koty(lvl NUMBER) IS
        SELECT
            connect_by_root imie imie,
            connect_by_root funkcja funkcja,
            LTRIM(REGEXP_SUBSTR(LTRIM(SYS_CONNECT_BY_PATH(imie ,','), ','), '\,.*'),',') szefowie,
            max(level) over () lvl
        FROM 
            Kocury
        WHERE
            szef IS NULL OR level = lvl
        CONNECT BY 
            PRIOR szef = pseudo AND level <= lvl
        START WITH 
            funkcja IN ('KOT', 'MILUSIA');
    liczba_przel NUMBER;
BEGIN
    liczba_przel := &liczba_przelozonych;    
    FOR k IN koty(liczba_przel + 1)
    LOOP
        DBMS_OUTPUT.PUT_LINE(k.imie || ' ' || k.funkcja || ' ' || k.szefowie || ' ' || k.lvl);    
    END LOOP;
END;


SET SERVEROUTPUT ON
DECLARE
    CURSOR koty(liczba NUMBER) IS
        SELECT
            K.imie im,
            K1.imie szef_1,
            NVL(K2.imie, ' ') szef_2,
            NVL(K3.imie, ' ') szef_3
        FROM 
            Kocury K
        INNER JOIN Kocury K1 ON K.szef = K1.pseudo AND K.funkcja IN ('KOT', 'MILUSIA')
        LEFT JOIN Kocury K2 ON K1.szef = K2.pseudo
        LEFT JOIN Kocury K3 ON K2.szef = K3.pseudo;
    liczba_przel NUMBER;
    str STRING(30);
BEGIN
    liczba_przel := &liczba_przelozonych;
    FOR k IN koty(liczba_przel)
    LOOP
        str := k.im;
        IF liczba_przel >= 1
            THEN str := str || ' '  || k.szef_1;
        END IF;
        IF liczba_przel >= 2
            THEN str := str || ' '  || k.szef_2;
        END IF;
        IF liczba_przel >= 3
            THEN str := str || ' '  || k.szef_3;
        END IF;
        DBMS_OUTPUT.PUT_LINE(str);
    END LOOP;
END;


--39
SET SERVEROUTPUT ON
DECLARE
    id_lower_than_zero EXCEPTION;
    PRAGMA EXCEPTION_INIT(id_lower_than_zero, -20000);
    index_bandy Bandy.nr_bandy%TYPE;
    nazwa_bandy Bandy.nazwa%TYPE;
    teren_bandy Bandy.teren%TYPE;
    licznik NUMBER;
    licznik_bledow NUMBER := 0;
BEGIN
    SAVEPOINT przedDodaniem;
    index_bandy := &index_bandy;
    IF index_bandy <=0
    THEN 
        RAISE id_lower_than_zero;
    END IF;
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE nr_bandy = index_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(index_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;
    
    nazwa_bandy := '&nazwa_bandy';    
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE nazwa = nazwa_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(nazwa_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;
    
    teren_bandy := '&teren_bandy';
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE teren = teren_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(teren_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;

    IF licznik_bledow = 0
    THEN
        DBMS_OUTPUT.PUT_LINE(index_bandy || ' ' || nazwa_bandy || ' ' || teren_bandy || ': utworzono');
        INSERT INTO Bandy 
        (nr_bandy, nazwa, teren) 
        VALUES 
        (index_bandy, nazwa_bandy, teren_bandy);
    END IF;
    ROLLBACK TO SAVEPOINT przedDodaniem;
END;

--40
CREATE OR REPLACE PROCEDURE dodawanie_bandy(index_bandy Bandy.nr_bandy%TYPE, 
                            nazwa_bandy Bandy.nazwa%TYPE, 
                            teren_bandy Bandy.teren%TYPE) AS
    id_lower_than_zero EXCEPTION;
    PRAGMA EXCEPTION_INIT(id_lower_than_zero, -20000);
    licznik NUMBER;
    licznik_bledow NUMBER := 0;
BEGIN
    SAVEPOINT przedDodaniem;
    IF index_bandy <=0
    THEN 
        RAISE id_lower_than_zero;
    END IF;
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE nr_bandy = index_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(index_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;
       
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE nazwa = nazwa_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(nazwa_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;
    
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE teren = teren_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(teren_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;

    IF licznik_bledow = 0
    THEN
        DBMS_OUTPUT.PUT_LINE(index_bandy || ' ' || nazwa_bandy || ' ' || teren_bandy || ': utworzono');
        INSERT INTO Bandy 
        (nr_bandy, nazwa, teren) 
        VALUES 
        (index_bandy, nazwa_bandy, teren_bandy);
    END IF;
    ROLLBACK TO SAVEPOINT przedDodaniem;
END;

SET SERVEROUTPUT ON
BEGIN
dodawanie_bandy(10, 'testowa', 'testowy');
END;

--41
CREATE OR REPLACE TRIGGER nowa_banda
BEFORE INSERT ON Bandy
FOR EACH ROW
DECLARE
    nr NUMBER;
BEGIN
    SELECT MAX(nr_bandy) INTO nr FROM Bandy;
    nr := nr + 1;
    :NEW.nr_bandy := nr;
END;

INSERT INTO Bandy(nr_bandy, nazwa) VALUES (15, 'testowa');
ROLLBACK;

--42.1

CREATE OR REPLACE PACKAGE zmiana_przydzialu 
IS 
   PROCEDURE inicjalizacja; 
 
   PROCEDURE dodaj_kota ( 
      pseudo_kota_nowy IN Kocury.pseudo%TYPE 
    , przydzial_kota_nowy IN Kocury.przydzial_myszy%TYPE 
   ); 
 
   PROCEDURE popraw_przydzialy; 
END;


SET SERVEROUTPUT ON
CREATE OR REPLACE PACKAGE BODY zmiana_przydzialu 
IS   
   TYPE kot_rd IS RECORD (   
        pseudo_kota Kocury.pseudo%TYPE, 
        przydzial_kota Kocury.przydzial_myszy%TYPE   
   );   
   
   TYPE koty_t IS TABLE OF kot_rd   
      INDEX BY PLS_INTEGER;   
   
   koty_info   koty_t;   
   poprawianie_w_trakcie BOOLEAN := FALSE;   
   
   PROCEDURE inicjalizacja   
   IS   
   BEGIN   
      koty_info.DELETE;   
   END;   
   
   PROCEDURE dodaj_kota (    
      pseudo_kota_nowy IN Kocury.pseudo%TYPE 
    , przydzial_kota_nowy IN Kocury.przydzial_myszy%TYPE 
   )   
   IS   
      index_kota   PLS_INTEGER := koty_info.COUNT + 1;   
   BEGIN   
      IF NOT poprawianie_w_trakcie   
      THEN   
         koty_info (index_kota).pseudo_kota := pseudo_kota_nowy;   
         koty_info (index_kota).przydzial_kota := przydzial_kota_nowy;  
      END IF;   
   END;   
   
   PROCEDURE popraw_przydzialy   
   IS   
      przydzial_tygrysa   Kocury.przydzial_myszy%TYPE;   
      index_kota         PLS_INTEGER;   
      zmiana NUMBER;
   BEGIN   
      IF NOT poprawianie_w_trakcie   
      THEN   
         poprawianie_w_trakcie := TRUE;   
   
         SELECT przydzial_myszy INTO przydzial_tygrysa
         FROM Kocury WHERE pseudo='TYGRYS';   
   
         WHILE (koty_info.COUNT > 0)   
         LOOP   
            index_kota := koty_info.FIRST;   
            
            SELECT przydzial_myszy - koty_info (index_kota).przydzial_kota 
            INTO zmiana
            FROM Kocury 
            WHERE pseudo = koty_info (index_kota).pseudo_kota;
            
            DBMS_OUTPUT.PUT_LINE('dane kota: ' || index_kota || ' ' || koty_info (index_kota).pseudo_kota || ' ' || koty_info (index_kota).przydzial_kota || ' ' || przydzial_tygrysa);
            DBMS_OUTPUT.PUT_LINE('zmiana: ' || zmiana);
            DBMS_OUTPUT.PUT_LINE('przydzial_tygrysa * 0.1: ' || przydzial_tygrysa * 0.1);
            
            IF zmiana < przydzial_tygrysa * 0.1
                THEN 
                    DBMS_OUTPUT.PUT_LINE('lower');
                    UPDATE Kocury 
                    SET 
                        przydzial_myszy = przydzial_myszy + zmiana, 
                        myszy_extra = NVL(myszy_extra, 0) + 5
                    WHERE funkcja = 'MILUSIA';
                    UPDATE Kocury
                    SET
                        przydzial_myszy = przydzial_myszy * 0.9
                    WHERE pseudo = 'TYGRYS';
                ELSE 
                    DBMS_OUTPUT.PUT_LINE('greater');
                    UPDATE Kocury
                    SET
                        myszy_extra = NVL(myszy_extra, 0) + 5
                    WHERE pseudo = 'TYGRYS';            
                END IF;
        
            koty_info.DELETE (koty_info.FIRST);   
         END LOOP;   
         poprawianie_w_trakcie := FALSE;  
      END IF;   
   END;   
END;

CREATE OR REPLACE TRIGGER zmiana_przydzialu_inicjalizaja 
   BEFORE INSERT OR UPDATE  
   ON Kocury 
BEGIN 
   LOCK TABLE Kocury IN EXCLUSIVE MODE; 
   zmiana_przydzialu.inicjalizacja; 
END;

CREATE OR REPLACE TRIGGER zmiana_przydzialu_dodaj_koty  
   AFTER INSERT OR UPDATE OF przydzial_myszy  
   ON Kocury  
   FOR EACH ROW  
BEGIN  
   zmiana_przydzialu.dodaj_kota (
      :OLD.pseudo, :OLD.przydzial_myszy);  
END;

CREATE OR REPLACE TRIGGER zmiana_przydzialu_popraw  
   AFTER INSERT OR UPDATE OF przydzial_myszy  
   ON Kocury  
BEGIN  
   zmiana_przydzialu.popraw_przydzialy;  
END;


--42.2

SET SERVEROUTPUT ON
CREATE OR REPLACE TRIGGER zmiana_przydzialu_compound
FOR UPDATE OF przydzial_myszy 
ON Kocury
COMPOUND TRIGGER
    TYPE kot_rd IS RECORD (   
        pseudo_kota Kocury.pseudo%TYPE, 
        przydzial_kota Kocury.przydzial_myszy%TYPE   
    );   
    
    TYPE koty_t IS TABLE OF kot_rd   
      INDEX BY PLS_INTEGER;   
    
    koty_info   koty_t;   
    poprawianie_w_trakcie BOOLEAN := FALSE;   
    
    BEFORE STATEMENT IS
    BEGIN      
        koty_info.DELETE;   
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
        index_kota   PLS_INTEGER := koty_info.COUNT + 1;   
    BEGIN
        IF NOT poprawianie_w_trakcie   
        THEN   
            koty_info (index_kota).pseudo_kota := :OLD.pseudo;   
            koty_info (index_kota).przydzial_kota := :OLD.przydzial_myszy;  
        END IF;   
    END AFTER EACH ROW;
    
    AFTER STATEMENT IS
        przydzial_tygrysa   Kocury.przydzial_myszy%TYPE;   
        index_kota  PLS_INTEGER;   
        zmiana  NUMBER;
    BEGIN   
        IF NOT poprawianie_w_trakcie   
        THEN   
            poprawianie_w_trakcie := TRUE;   
            
            SELECT przydzial_myszy INTO przydzial_tygrysa
            FROM Kocury WHERE pseudo='TYGRYS';   
            
            WHILE (koty_info.COUNT > 0)   
            LOOP   
                index_kota := koty_info.FIRST;   
                
                SELECT przydzial_myszy - koty_info (index_kota).przydzial_kota 
                INTO zmiana
                FROM Kocury 
                WHERE pseudo = koty_info (index_kota).pseudo_kota;
                
                DBMS_OUTPUT.PUT_LINE('dane kota: ' || index_kota || ' ' || koty_info (index_kota).pseudo_kota || ' ' || koty_info (index_kota).przydzial_kota || ' ' || przydzial_tygrysa);
                DBMS_OUTPUT.PUT_LINE('zmiana: ' || zmiana);
                DBMS_OUTPUT.PUT_LINE('przydzial_tygrysa * 0.1: ' || przydzial_tygrysa * 0.1);
                
                IF zmiana < przydzial_tygrysa * 0.1
                    THEN 
                        DBMS_OUTPUT.PUT_LINE('lower');
                        UPDATE Kocury 
                        SET 
                            przydzial_myszy = przydzial_myszy + zmiana, 
                            myszy_extra = NVL(myszy_extra, 0) + 5
                        WHERE funkcja = 'MILUSIA';
                        UPDATE Kocury
                        SET
                            przydzial_myszy = przydzial_myszy * 0.9
                        WHERE pseudo = 'TYGRYS';
                    ELSE 
                        DBMS_OUTPUT.PUT_LINE('greater');
                        UPDATE Kocury
                        SET
                            myszy_extra = NVL(myszy_extra, 0) + 5
                        WHERE pseudo = 'TYGRYS';            
                    END IF;
                koty_info.DELETE (koty_info.FIRST);   
            END LOOP;   
            poprawianie_w_trakcie := FALSE;  
        END IF;   
    END AFTER STATEMENT;
END;

SET SERVEROUTPUT ON
CREATE OR REPLACE TRIGGER zmiana_przydzialu_compound
FOR UPDATE OF przydzial_myszy 
ON Kocury
COMPOUND TRIGGER
    BEFORE STATEMENT IS
    BEGIN      
        zmiana_przydzialu.inicjalizacja;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
       zmiana_przydzialu.dodaj_kota (
          :OLD.pseudo, :OLD.przydzial_myszy);  
    END AFTER EACH ROW;
    
    AFTER STATEMENT IS
    BEGIN   
        zmiana_przydzialu.popraw_przydzialy;  
    END AFTER STATEMENT;
END;


SAVEPOINT przed_zmiana_przydzialu;
ROLLBACK TO SAVEPOINT przed_zmiana_przydzialu;

BEGIN
    UPDATE Kocury SET przydzial_myszy = 45 WHERE pseudo = 'ZERO';
    ROLLBACK;
END;

BEGIN
    UPDATE Kocury SET przydzial_myszy = 60 WHERE pseudo = 'ZERO';
    ROLLBACK;
END;


--43

SET SERVEROUTPUT ON
DECLARE
    str STRING(300);
    CURSOR funkcje IS
        SELECT
            funkcja
        FROM
            Funkcje;
    CURSOR bandy IS
        SELECT
            nazwa,
            nr_bandy
        FROM
            Bandy;
    CURSOR plcie IS
        SELECT
            plec
        FROM
            Kocury
        GROUP BY 
            plec;

    liczba_myszy NUMBER;
    liczba_kotow NUMBER;
BEGIN
    str := 'NAZWA BANDY      PLEC  ILE';
    FOR f IN funkcje
    LOOP
        str := str || LPAD(f.funkcja, 10);
    END LOOP;
    str := str || LPAD('SUMA', 10);
    DBMS_OUTPUT.PUT_LINE(str);    
    
    FOR b IN bandy
    LOOP
        FOR p in plcie
        LOOP
            SELECT
                COUNT(*)
            INTO
                liczba_kotow
            FROM
                Kocury
            WHERE
                plec = p.plec AND 
                nr_bandy = b.nr_bandy;
                
            IF liczba_kotow <> 0
            THEN
                str := RPAD(b.nazwa, 17);
                IF p.plec = 'D'
                    THEN str:= str || 'Kotka';
                    ELSE str:= str || 'Kocur';
                END IF;
                str:= str || LPAD(liczba_kotow, 4);
                FOR f IN funkcje
                LOOP
                    SELECT 
                        NVL(SUM(przydzial_myszy + NVL(myszy_extra, 0)), 0)
                    INTO
                        liczba_myszy
                    FROM
                        Kocury
                    WHERE
                        nr_bandy = b.nr_bandy AND funkcja = f.funkcja AND plec = p.plec;
                    str := str || LPAD(liczba_myszy, 10);
                END LOOP;
                SELECT 
                    NVL(SUM(przydzial_myszy + NVL(myszy_extra, 0)), 0)
                INTO
                    liczba_myszy
                FROM
                    Kocury
                WHERE
                    nr_bandy = b.nr_bandy AND plec = p.plec;
                str := str || LPAD(liczba_myszy, 10);
                DBMS_OUTPUT.PUT_LINE(str);
            END IF;
        END LOOP;
    END LOOP;
    str := RPAD('ZJADA RAZEM', 26);
    FOR f in funkcje
    LOOP
        SELECT 
            NVL(SUM(przydzial_myszy + NVL(myszy_extra, 0)), 0)
        INTO
            liczba_myszy
        FROM
            Kocury
        WHERE
         funkcja = f.funkcja;
         str := str || LPAD(liczba_myszy, 10);
    END LOOP;
    SELECT 
        NVL(SUM(przydzial_myszy + NVL(myszy_extra, 0)), 0)
    INTO
        liczba_myszy
    FROM
        Kocury;
    str := str || LPAD(liczba_myszy, 10);    
    DBMS_OUTPUT.PUT_LINE(str);
END;



--44
CREATE OR REPLACE FUNCTION podatek(pseudo_kota Kocury.pseudo%TYPE) RETURN NUMBER IS
    liczba_myszy Kocury.przydzial_myszy%TYPE;
    podatek_kota NUMBER := 0;
    liczba_podwladnych NUMBER := 0;
    liczba_wrogow NUMBER := 0;
    liczba_psich_wrogow NUMBER := 0;
BEGIN
    SELECT
        SUM(przydzial_myszy + NVL(myszy_extra, 0))
    INTO
        liczba_myszy
    FROM
        Kocury
    WHERE
        pseudo = pseudo_kota;
    podatek_kota := podatek_kota + CEIL(liczba_myszy * 0.05);
    DBMS_OUTPUT.PUT_LINE('podatek 5%: '|| CEIL(liczba_myszy * 0.05) || ' (' || liczba_myszy || '*0.5)=' || liczba_myszy * 0.05);
    
    SELECT
        COUNT(*)
    INTO
        liczba_podwladnych
    FROM
        Kocury
    WHERE
        szef = pseudo_kota;
    IF liczba_podwladnych = 0
        THEN podatek_kota := podatek_kota + 2;
            DBMS_OUTPUT.PUT_LINE('brak podwladnych');
    END IF;
    
    
    SELECT
        COUNT(*)
    INTO
        liczba_wrogow
    FROM
        Wrogowie_Kocurow
    WHERE
         pseudo = pseudo_kota;
    IF liczba_wrogow = 0
        THEN podatek_kota := podatek_kota + 1;
        DBMS_OUTPUT.PUT_LINE('brak wrogow');
    END IF;
    
    SELECT
        COUNT(*)
    INTO
        liczba_psich_wrogow
    FROM
        Wrogowie_Kocurow
    NATURAL JOIN 
        Wrogowie
    WHERE
         pseudo = pseudo_kota AND 
         gatunek = 'PIES';
    IF liczba_psich_wrogow = 0
        THEN podatek_kota := podatek_kota + 1;
        DBMS_OUTPUT.PUT_LINE('brak psich wrogow');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('podatek dla ' || pseudo_kota || ' => ' || podatek_kota);
    RETURN podatek_kota;
END;

SELECT
    K.pseudo,
    W.imie_wroga,
    gatunek
FROM 
    Kocury K
LEFT JOIN 
    Wrogowie_Kocurow WK
    ON K.pseudo = WK.pseudo
LEFT JOIN 
    Wrogowie W
    ON W.imie_wroga = WK.imie_wroga;

SELECT
    K1.pseudo,
    COUNT(K2.pseudo)
FROM
    Kocury K1
LEFT JOIN 
    Kocury K2
    ON K1.pseudo = K2.szef
GROUP BY 
    K1.pseudo;

SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE(podatek('TYGRYS'));
    --ma wroga, ma podwladnych, ma wroga psa, podatek 5% -> 7
END;

SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE(podatek('ZOMBI'));
    --ma wroga, ma podwladnych, nie ma wroga psa, podatek 5% -> 5 + 1
END;

SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE(podatek('RAFA'));
    --nie ma wroga, ma podwladnych, nie ma wroga psa, podatek 5% -> 4 + 1 + 1
END;

SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE(podatek('LOLA'));
    --nie ma wroga, nie ma podwladnych, nie ma wroga psa, podatek 5% -> 4 + 1 + 1 + 2
END;


CREATE OR REPLACE PACKAGE pakiet1 IS
    PROCEDURE dodawanie_bandy(index_bandy Bandy.nr_bandy%TYPE, 
                            nazwa_bandy Bandy.nazwa%TYPE, 
                            teren_bandy Bandy.teren%TYPE);
    FUNCTION podatek(pseudo_kota Kocury.pseudo%TYPE) 
        RETURN NUMBER;
END;

CREATE OR REPLACE PACKAGE BODY pakiet1 IS
    PROCEDURE dodawanie_bandy(index_bandy Bandy.nr_bandy%TYPE, 
                                nazwa_bandy Bandy.nazwa%TYPE, 
                                teren_bandy Bandy.teren%TYPE) AS
        id_lower_than_zero EXCEPTION;
        PRAGMA EXCEPTION_INIT(id_lower_than_zero, -20000);
        licznik NUMBER;
        licznik_bledow NUMBER := 0;
    BEGIN
        SAVEPOINT przedDodaniem;
        IF index_bandy <=0
        THEN 
            RAISE id_lower_than_zero;
        END IF;
        SELECT COUNT(*) INTO licznik FROM Bandy WHERE nr_bandy = index_bandy;
        IF licznik > 0
        THEN 
            DBMS_OUTPUT.PUT_LINE(index_bandy || ': ju? istnieje');
            licznik_bledow := licznik_bledow + 1;
        END IF;
           
        SELECT COUNT(*) INTO licznik FROM Bandy WHERE nazwa = nazwa_bandy;
        IF licznik > 0
        THEN 
            DBMS_OUTPUT.PUT_LINE(nazwa_bandy || ': ju? istnieje');
            licznik_bledow := licznik_bledow + 1;
        END IF;
        
        SELECT COUNT(*) INTO licznik FROM Bandy WHERE teren = teren_bandy;
        IF licznik > 0
        THEN 
            DBMS_OUTPUT.PUT_LINE(teren_bandy || ': ju? istnieje');
            licznik_bledow := licznik_bledow + 1;
        END IF;
    
        IF licznik_bledow = 0
        THEN
            DBMS_OUTPUT.PUT_LINE(index_bandy || ' ' || nazwa_bandy || ' ' || teren_bandy || ': utworzono');
            INSERT INTO Bandy 
            (nr_bandy, nazwa, teren) 
            VALUES 
            (index_bandy, nazwa_bandy, teren_bandy);
        END IF;
        ROLLBACK TO SAVEPOINT przedDodaniem;
    END;

    FUNCTION podatek(pseudo_kota Kocury.pseudo%TYPE) RETURN NUMBER IS
        liczba_myszy Kocury.przydzial_myszy%TYPE;
        podatek_kota NUMBER := 0;
        liczba_podwladnych NUMBER := 0;
        liczba_wrogow NUMBER := 0;
        liczba_psich_wrogow NUMBER := 0;
    BEGIN
        SELECT
            SUM(przydzial_myszy + NVL(myszy_extra, 0))
        INTO
            liczba_myszy
        FROM
            Kocury
        WHERE
            pseudo = pseudo_kota;
        podatek_kota := podatek_kota + CEIL(liczba_myszy * 0.05);
        DBMS_OUTPUT.PUT_LINE('podatek 5%: '|| CEIL(liczba_myszy * 0.05) || ' (' || liczba_myszy || '*0.5)=' || liczba_myszy * 0.05);
        
        SELECT
            COUNT(*)
        INTO
            liczba_podwladnych
        FROM
            Kocury
        WHERE
            szef = pseudo_kota;
        IF liczba_podwladnych = 0
            THEN podatek_kota := podatek_kota + 2;
                DBMS_OUTPUT.PUT_LINE('brak podwladnych');
        END IF;
        
        
        SELECT
            COUNT(*)
        INTO
            liczba_wrogow
        FROM
            Wrogowie_Kocurow
        WHERE
             pseudo = pseudo_kota;
        IF liczba_wrogow = 0
            THEN podatek_kota := podatek_kota + 1;
            DBMS_OUTPUT.PUT_LINE('brak wrogow');
        END IF;
        
        SELECT
            COUNT(*)
        INTO
            liczba_psich_wrogow
        FROM
            Wrogowie_Kocurow
        NATURAL JOIN 
            Wrogowie
        WHERE
             pseudo = pseudo_kota AND 
             gatunek = 'PIES';
        IF liczba_psich_wrogow = 0
            THEN podatek_kota := podatek_kota + 1;
            DBMS_OUTPUT.PUT_LINE('brak psich wrogow');
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('podatek dla ' || pseudo_kota || ' => ' || podatek_kota);
        RETURN podatek_kota;
    END;
END;

DECLARE
    CURSOR koty IS
        SELECT
            pseudo
        FROM
            Kocury;
    podatki NUMBER := 0;
BEGIN
    FOR k IN koty
    LOOP
        podatki := podatki + pakiet1.podatek(k.pseudo);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('podatki: ' || podatki);
END;

--45
CREATE TABLE Dodatki_extra (
    nr_dodatku NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT "DO_NR_DODATKU_PK" PRIMARY KEY,
    pseudo VARCHAR2(15) CONSTRAINT "DO_PSEUDO_NN" NOT NULL,
    dod_extra NUMBER(3,0) CONSTRAINT "DO_DOD_EXTRA_NN" NOT NULL
);

DROP TABLE Dodatki_extra;

SET SERVEROUTPUT ON
CREATE OR REPLACE TRIGGER zmiana_przydzialu_milus  
   AFTER UPDATE  
   ON Kocury  
   FOR EACH ROW  
DECLARE
    pseudo Dodatki_extra.pseudo%TYPE;
    polecenie STRING(100);
BEGIN  
    IF LOGIN_USER <> 'TYGRYS'
    THEN
        IF :OLD.funkcja = 'MILUSIA'
        THEN
            IF :NEW.przydzial_myszy > :OLD.przydzial_myszy OR :NEW.myszy_extra > :OLD.myszy_extra
            THEN
                pseudo := :NEW.pseudo;
                polecenie := 'INSERT INTO Dodatki_extra (pseudo, dod_extra) VALUES (''' || pseudo || ''', -10)';
                DBMS_OUTPUT.PUT_LINE(polecenie);
                EXECUTE IMMEDIATE polecenie;
            END IF;
        END IF;
    END IF;
END;

UPDATE Kocury SET przydzial_myszy = 25 WHERE pseudo = 'PUSZYSTA';
ROLLBACK;
--46

CREATE TABLE Niewlasciwe_przydzialy_myszy (
    nr NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT "NPM_NR_PK" PRIMARY KEY,
    uzytkownik VARCHAR2(15) CONSTRAINT "NPM_UZYTKOWNIK_NN" NOT NULL,
    data_proby DATE CONSTRAINT "NPM_DATA_PROBY_NN" NOT NULL,
    pseudo_kota VARCHAR2(15) CONSTRAINT "NPM_PSEUDO_KOTA_NN" NOT NULL,
    operacja VARCHAR2(15) CONSTRAINT "NPM_OPERACJA_NN" NOT NULL
);

DROP TABLE Niewlasciwe_przydzialy_myszy;

CREATE OR REPLACE TRIGGER spr_zmiany_przydzialu
BEFORE INSERT OR UPDATE OF przydzial_myszy
ON Kocury
FOR EACH ROW
DECLARE
    min_przydzial NUMBER;
    max_przydzial NUMBER;
    uzytk Niewlasciwe_przydzialy_myszy.uzytkownik%TYPE;
    data_pr Niewlasciwe_przydzialy_myszy.data_proby%TYPE;
    pseudo Niewlasciwe_przydzialy_myszy.pseudo_kota%TYPE;
    oper Niewlasciwe_przydzialy_myszy.operacja%TYPE;
    PRAGMA AUTONOMOUS_TRANSACTION;    
BEGIN
    SELECT
        min_myszy,
        max_myszy
    INTO
        min_przydzial,
        max_przydzial
    FROM Funkcje
    WHERE
        funkcja = :NEW.funkcja;
    
    IF (:NEW.przydzial_myszy < min_przydzial OR :NEW.przydzial_myszy > max_przydzial)
    THEN
        begin
            case
                when inserting then
                    oper:= 'INSERT';
                when updating then
                    oper:= 'UPDATE';
            end case;
        end;
        uzytk := LOGIN_USER;
        data_pr := SYSDATE;
        pseudo := :NEW.pseudo;
        INSERT INTO Niewlasciwe_przydzialy_myszy (uzytkownik, data_proby, pseudo_kota, operacja) 
        VALUES (uzytk, data_pr, pseudo, oper); 
        COMMIT;
        raise_application_error(-20000, 'Wartosc nie miesci sie w zakresie przydzialu funkcji');
    END IF;
END;

UPDATE Kocury SET przydzial_myszy = 300 WHERE pseudo = 'TYGRYS';

ROLLBACK;



