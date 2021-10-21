-- Скалярная функция.
-- Максимальную сумму, которую придется потратить, если все промокоды будут использованы

drop function if exists max_price_sum(promo_limit integer, price integer);

create or replace function max_price_sum(promo_limit integer, price integer) returns DECIMAL as $$
begin
    return promo_limit * price;
end;
$$ language PLPGSQL;

select price, "limit", max_price_sum("limit", price)
from promocodes
where "limit" < 1500;


-- Подставляемая табличная функция
-- Вывод использований промокодов клиентами
drop function if exists getPromoUsages();

create or replace function getPromoUsages()
returns table
        (
            first_name varchar(30),
            last_name varchar(30),
            usage_date date
        ) as $$
begin
    return query select c.first_name, c.last_name, cpu.added_at
		   		 from clients as c
                 inner join client_promocode_usages cpu on c.id = cpu.client_id
    ;
end;
$$ language PLPGSQL;

SELECT *
FROM getPromoUsages();


-- Многооператорная табличная функция
-- Вывод использований промокодов клиентами
DROP FUNCTION IF EXISTS getPromoUsages();

create or replace function getPromoUsages()
returns table
        (
            first_name varchar(30),
            last_name varchar(30),
            usage_date date
        ) as $$
begin
    drop table if exists getPromoUsages;

    create temp table getPromoUsages(
        first_name varchar(30),
        last_name varchar(30),
        usage_date date
    );

    insert into getPromoUsages (first_name, last_name, usage_date)
    select c.first_name, c.last_name, cpu.added_at
		   		 from clients as c
                 inner join client_promocode_usages cpu on c.id = cpu.client_id;

    return query select * from getPromoUsages;
end;
$$ language PLPGSQL;

--
SELECT *
FROM getPromoUsages();

--
-- Функция с рекурсивным ОТВ.
-- получаем сумму скидки по клиенту после каждого заказа и выводим сам номер заказа
drop function if exists recursion();
drop table if exists orders_discount;

create temp table orders_discount(
    promo_id integer,
    promo_limit integer,
    discount integer,
    order_num integer
);

create or replace function recursion()
returns setof orders_discount AS $$
begin
    return query
        with recursive orders_discount (promo_id, promo_limit, discount, order_num) as (
            select p.id, p."limit", p.price, (1) as order_num
            from promocodes as p
            where p."limit" < 5
            union all
            select promo_id, promo_limit, (discount / order_num) + discount, order_num + 1
            from orders_discount
            where order_num < promo_limit and promo_limit < 5
        )
        select promo_id, discount, promo_limit, order_num
        from orders_discount;
end;
$$ language PLPGSQL;

-- Основной запрос.
SELECT *
FROM recursion()
order by promo_id, order_num;