--client_promocode_usages constraints
alter table marketing.client_promocode_usages
    drop constraint if exists cpu_order_price;
-- alter table marketing.client_promocode_usages
--     add constraint cpu_order_price check ( order_price >= 0 );

alter table marketing.client_promocode_usages
    drop constraint if exists cpu_order_discount;
alter table marketing.client_promocode_usages
    add constraint cpu_order_discount check ( order_discount >= 0 );


--coupons constraints
alter table marketing.coupons
    drop constraint if exists coupons_max_discount;
alter table marketing.coupons
    add constraint coupons_max_discount check ( max_discount >= 0 );

alter table marketing.coupons
    drop constraint if exists coupons_min_price;
alter table marketing.coupons
    add constraint coupons_min_price check ( min_price >= 0 );

alter table marketing.coupons
    drop constraint if exists coupons_dates;
alter table marketing.coupons
    add constraint coupons_dates check (date_start <= date_end);

--promocodes constraints
alter table marketing.promocodes
    drop constraint if exists p_code;
alter table marketing.promocodes
    add constraint p_code unique (code);

alter table marketing.promocodes
    drop constraint if exists p_price;
alter table marketing.promocodes
    add constraint p_price check ( price >= 0 );

alter table marketing.promocodes
    drop constraint if exists p_count;
alter table marketing.promocodes
    add constraint p_count check ( count >= 0 );

--clients constraints
alter table marketing.clients
    drop constraint if exists c_age;
alter table marketing.clients
    add constraint c_age check ( age > 0 );

alter table marketing.clients
    drop constraint if exists c_orders_count;
alter table marketing.clients
    add constraint c_orders_count check ( orders_count >= 0 );

alter table marketing.clients
    drop constraint if exists c_dates;
alter table marketing.clients
    add constraint c_dates check ( first_order_date <= last_order_date );

alter table marketing.clients
    drop constraint if exists c_rating;
alter table marketing.clients
    add constraint c_rating check ( rating >= 0 and rating <= 10 );

drop trigger if exists cpu_stamp on marketing.client_promocode_usages;
create trigger cpu_stamp
    before insert or update
    on marketing.client_promocode_usages
    for each row
execute procedure public.cpu_stamp();

drop function if exists cpu_stamp;
create function cpu_stamp() returns trigger
    language plpgsql
as
$$
DECLARE
    rating integer ;
BEGIN
        -- проверяем соответствие рейтинга и скидки
        rating := (select c.rating from marketing.clients as c where c.id = new.client_id);
        if new.order_discount >= new.order_price * rating / 10 then
            new.order_discount := new.order_price * rating / 10;
        end if;

        new.order_discount := new.order_price * rating / 10;
        RETURN NEW;
    END;
$$;

alter function cpu_stamp() owner to postgres;