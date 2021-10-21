-- Хранимая процедура с параметрами.
-- Изменить рейтинг клиента
CREATE OR REPLACE PROCEDURE change_rating(client_id integer, rating_change integer)
AS $$
BEGIN
    IF rating_change > 0 THEN
    UPDATE clients SET rating = rating + rating_change WHERE id = client_id AND rating + rating_change <= 10;
    END IF;

    IF rating_change < 0 THEN
    UPDATE clients SET rating = rating + rating_change WHERE id = client_id AND rating + rating_change >= 0;
    END IF;

    COMMIT;
END;
$$ LANGUAGE PLPGSQL;

CALL change_rating(12, -1);

-- хранимая процедура с рекурсивным ОТВ
-- получаем сумму скидки по клиенту после каждого заказа и выводим сам номер заказа
drop table if exists order_discount;

create temp table order_discount(
    promo_id integer,
    promo_limit integer,
    discount integer,
    order_num integer
);

CREATE OR REPLACE PROCEDURE orders_discount_sum(max_limit integer)
AS $$
BEGIN
    insert into order_discount (
    with recursive orders_discount (promo_id, promo_limit, discount, order_num) as (
        select p.id, p."limit", p.price, (1) as order_num
        from promocodes as p
        where p."limit" < max_limit
        union all
        select promo_id, promo_limit, (discount / order_num) + discount, order_num + 1
        from orders_discount
        where order_num < promo_limit and promo_limit < max_limit
    )
    select promo_id, discount, promo_limit, order_num
    from orders_discount
    );
END;
$$ LANGUAGE PLPGSQL;

CALL orders_discount_sum(5);

select * from order_discount order by promo_id, order_num;

-- Хранимая процедура с курсором
-- Выводит активных клиентов с заданным рейтингом
CREATE OR REPLACE PROCEDURE get_active_clients_by_rating(c_rating integer)
AS $$
DECLARE
    clients_rec RECORD;
    clients_cur CURSOR FOR
        SELECT * FROM clients c
        WHERE c.active AND c.rating = c_rating;
BEGIN
    OPEN clients_cur;
    LOOP
        FETCH clients_cur INTO clients_rec;
        RAISE NOTICE '% %, рейтинг %', clients_rec.first_name, clients_rec.last_name, c_rating;
        EXIT WHEN NOT FOUND;
    END LOOP;
    CLOSE clients_cur;
END;
$$ LANGUAGE PLPGSQL;

CALL get_active_clients_by_rating(1);

-- Хранимая процедура доступа к метаданным.
-- Выводит имя, ID и возможность соединений с бд
-- по имени БД.
CREATE OR REPLACE PROCEDURE get_db_metadata(dbname VARCHAR)
AS $$
DECLARE
    db_id int;
    db_allow_conn bool;
BEGIN
    SELECT pg.oid, pg.datallowconn FROM pg_database pg WHERE pg.datname = dbname
    INTO db_id, db_allow_conn;
    RAISE NOTICE 'DB: %, ID: %, allow conn: %', dbname, db_id, db_allow_conn;
END;
$$ LANGUAGE PLPGSQL;

CALL get_db_metadata('marketing_db');

-- Защита: процедура с вложенным тройным селектом

drop table if exists wrong_promocodes;

create temp table wrong_promocodes(
    id              serial                                    not null,
    coupon_id       integer                                   not null,
    code            varchar(30) default ''::character varying not null,
    price           integer     default 0                     not null,
    "limit"         integer,
    count           integer     default 0                     not null,
    email           varchar(50),
    company         varchar(70),
    for_first_order boolean     default false
);

CREATE OR REPLACE PROCEDURE check_promocodes()
AS $$
BEGIN
    insert into wrong_promocodes (
    select * from promocodes p
    where p.id in (
            select promocode_id
            from client_promocode_usages
            group by promocode_id
            having count(promocode_id) > (
                select promocodes."limit"
                from promocodes
                where  promocode_id=promocodes.id
                )
            )
    )
    ;
END;
$$ LANGUAGE PLPGSQL;

CALL check_promocodes();

select * from wrong_promocodes;