-- 1. Определяемую пользователем скалярную функцию CLR,
CREATE OR REPLACE FUNCTION get_surname_by_id(id INTEGER) 
    RETURNS TEXT
    LANGUAGE plpython3u
AS
$$
    surname = plpy.execute(f"\
        SELECT d.surname\n\
        FROM driver d\n\
        WHERE d.driver_id = '{id}'\n\
        LIMIT 1;"
    )
    
    return surname[0]["surname"]
$$;
-- SELECT get_surname_by_id(395);


-- 2. Пользовательская агрегатная функция CLR
CREATE OR REPLACE FUNCTION _agg_oldest(current DATE, new DATE) 
    RETURNS DATE
    LANGUAGE plpython3u
AS
$$
    import datetime as dt

    current_oldest = dt.datetime(int(current.split('-')[0]), int(current.split('-')[1]), int(current.split('-')[2]))
    try:
        challenger = dt.datetime(int(new.split('-')[0]), int(new.split('-')[1]), int(new.split('-')[2]))
    except:
        challenger = dt.datetime.today()

    maxi = current
    if (current_oldest - challenger).days > 0:
        maxi = new
    return maxi
$$;

CREATE OR REPLACE AGGREGATE max_age(DATE) (
    sfunc = _agg_oldest,
    stype = DATE,
    initcond = '5999-12-31'
);

-- SELECT max_age(dob)
-- FROM driver;


-- 3. Определяемая пользователем табличная функция CLR
CREATE OR REPLACE FUNCTION get_driver_by_nat_count() 
    RETURNS TABLE(
        nationality TEXT,
        cnt INT
    )
    LANGUAGE plpython3u
AS
$$
    result_table = []
    unique_nats = plpy.execute("\c
        SELECT DISTINCT nationality\n\
        FROM driver;"
    )
    
    for nationality in unique_nats:
        if nationality["nationality"] != '-':
            result_table.append(
                {
                    "nationality": nationality["nationality"],
                    "cnt": plpy.execute(f"\
                        SELECT COUNT(driver_id)\n\
                        FROM driver\n\
                        WHERE nationality = '{nationality['nationality']}';"
                    )[0]["count"]
                }
            )
    return result_table
$$;

-- SELECT *
-- FROM get_driver_by_nat_count()
-- ORDER BY cnt DESC;


-- 4. Хранимая процедура CLR
CREATE OR REPLACE PROCEDURE id_by_surname(surname VARCHAR)
    LANGUAGE plpython3u
AS
$$
    import requests
    import datetime as dt

    id = plpy.execute(f"\
        SELECT driver_id\n\
        FROM driver\n\
        WHERE surname = '{surname}';"
        )[0]["driver_id"]

    if id == 0:
        plpy.notice(
            f"There is no driver with '{surname}' surname."
        )
    else:
        plpy.notice(
            f"There is id '{id}' for driver with '{surname}' surname."
        )
$$;


-- CALL id_by_surname('Hamilton');   
-- CALL id_by_surname('Sarkisov');   


-- 5. Триггер CLR
CREATE OR REPLACE FUNCTION driver_insert_delete_natif() 
    RETURNS TRIGGER
    LANGUAGE plpython3u
AS
$$
    if TD['event'] == 'INSERT':
        plpy.notice(
            f"There was insertion to driver table."
        )
    if TD['event'] == 'DELETE':
        plpy.notice(
            f"There was deletion to driver table."
        )
$$;

CREATE TRIGGER driver_insert_delete_natif_tg
    BEFORE INSERT OR DELETE
    ON driver
FOR EACH STATEMENT
EXECUTE PROCEDURE driver_insert_delete_natif();


-- 6. Определяемый пользователем тип данных CLR
CREATE TYPE driver_t AS (
    driver_id INT,
    surname VARCHAR, 
    dob DATE
);

CREATE OR REPLACE FUNCTION get_driver_info(driver_id INT) 
    RETURNS driver_t
    LANGUAGE plpython3u
AS
$$
    dob = plpy.execute(f"\
        SELECT d.dob\n\
        FROM driver d\n\
        WHERE d.driver_id = '{driver_id}';"
    )[0]["dob"]
    surname = plpy.execute(f"\
        SELECT d.surname\n\
        FROM driver d\n\
        WHERE d.driver_id = '{driver_id}';"
    )[0]["surname"]
    return (driver_id, surname, dob)
$$;


CREATE TABLE driver_test (driver_info driver_t)

INSERT INTO driver_test 
    SELECT get_driver_info(1); 
INSERT INTO driver_test 
    SELECT get_driver_info(2);
INSERT INTO driver_test 
    SELECT get_driver_info(3);



SELECT (driver_info::driver_t).surname surname
FROM driver_test
WHERE driver_info IN (
    SELECT get_driver_info(1)
);

DELETE FROM testing
WHERE (info::daydata_t).cnt < 350;

UPDATE testing
SET info = ((info::daydata_t).iata, '5999-12-31', (info::daydata_t).cnt);