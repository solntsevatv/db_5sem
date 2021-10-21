-- Триггер AFTER.
-- Не дает увеличить кол-во промиков в таблице если уже лимит .
CREATE OR REPLACE FUNCTION check_count_and_limit()
RETURNS TRIGGER
AS $$
BEGIN
    IF new.count > new."limit" THEN
        RAISE EXCEPTION 'promo limit with id % is exceeded. Aborting.', NEW.id;
    END IF;
    return new;
END;
$$ LANGUAGE PLPGSQL;

drop trigger if exists check_price_and_discount on promocodes;

CREATE TRIGGER check_count_and_limit AFTER UPDATE ON promocodes
FOR ROW EXECUTE PROCEDURE check_count_and_limit();

update promocodes set count = count + 1
where id = 25;

-- Триггер INSTEAD OF
-- не дает вставить промокод со скидкой больше маскимальной по купону
CREATE OR REPLACE FUNCTION view_insert_promo()
RETURNS TRIGGER
AS $$
DECLARE
    max_discount INT;
BEGIN
    SELECT c.max_discount FROM coupons c
    WHERE c.id = NEW.coupon_id
    INTO max_discount;

    IF NEW.price > max_discount THEN
        RAISE EXCEPTION 'Promo discount is exceeded';
    ELSE
        INSERT INTO promocodes (id, coupon_id, code, price, "limit", count, email, company, for_first_order)
        VALUES (
            NEW.id,
            NEW.coupon_id,
            NEW.code,
            NEW.price,
            NEW."limit",
            NEW.count,
            NEW.email,
            NEW.company,
            NEW.for_first_order
        );
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE VIEW my_view_promo AS
SELECT * FROM promocodes LIMIT 10;

CREATE TRIGGER view_insert_promo
    INSTEAD OF insert on my_view_promo
    FOR EACH ROW
    EXECUTE PROCEDURE view_insert_promo();

-- max_discount for 324 is 909
insert into my_view_promo(id, coupon_id, code, price, "limit", count)
values (1001, 324, 'HAHAHHAH2', 910, 20, 0)