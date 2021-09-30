-- 1 Инструкция SELECT, использующая предикат сравнения
select c.last_name, c.first_name, c.rating
from marketing.clients as c
where c.rating > 5
order by c.rating desc
limit 100;

-- 2 Инструкция SELECT, использующая предикат BETWEEN
select coupons.name, coupons.date_end
from marketing.coupons as coupons
where coupons.date_end between '2021-08-01' and '2021-08-31';

-- 3 Инструкция SELECT, использующая предикат LIKE
select p.code, p.price, p.email
from marketing.promocodes as p
where p.email like '%@mail.ru';

-- 4 Инструкция SELECT, использующая предикат IN с вложенным подзапросом
select *
from marketing.client_promocode_usages as cpu
where cpu.client_id in (select id
                        from marketing.clients
                        where rating < 5 and comment like '%агрессивный%');

-- 5 Инструкция SELECT, использующая предикат EXISTS с вложенным подзапросом
-- клиенты, которые пользовались промокодами
select c.id, c.last_name, c.first_name
from marketing.clients as c
where exists(select c.id
    from marketing.clients left join marketing.client_promocode_usages as cpu
    on c.id = cpu.client_id
    where cpu.client_id is not null);

-- 6 Инструкция SELECT, использующая предикат сравнения с квантором.
select coupons.id, coupons.name, coupons.source
from marketing.coupons
where 'A' = any(coupons.source);

-- 7 Инструкция SELECT, использующая агрегатные функции в выражениях столбцов.
select client_id, sum(order_price) as orders_price_sum, count(order_price) as orders_count
from marketing.client_promocode_usages
group by client_id;

-- 8 Инструкция SELECT, использующая скалярные подзапросы в выражениях столбцов
select p.id, p.code, p."limit", (
    select avg(cn.max_discount)
    from coupons as cn
    where p.coupon_id = cn.id
    ) as avg_max_discount
from promocodes as p
where p.for_first_order;

-- 9 Инструкция SELECT, использующая простое выражение CASE
select id, name, date_start,
        case (select extract(month from date_end))
            when (select extract(month from current_date)) then 'this month'
            when (select extract(month from current_date) + 1) then 'next month'
            else 'other_date'
        end as date_end
from coupons
where (select extract(year from date_end))=(select extract(year from current_date))
order by date_end desc;

-- 10 Инструкция SELECT, использующая поисковое выражение CASE
select id, name, date_start,
        case
            when (select extract(month from date_end))=(select extract(month from current_date)) then 'this month'
            when (select extract(month from date_end))>(select extract(month from current_date)) then 'next months'
            else 'last months'
        end as date_end
from coupons
where (select extract(year from date_end))=(select extract(year from current_date))
order by date_end desc;

-- 11 Создание новой временной локальной таблицы из результирующего набора данных инструкции SELECT
drop table if exists last_client_usages;

SELECT id, client_id, promocode_id, added_at into last_client_usages
FROM marketing.client_promocode_usages
where added_at > current_date - 30;

select * from last_client_usages;

-- 12 Инструкция SELECT, использующая вложенные коррелированные
-- подзапросы в качестве производных таблиц в предложении FROM.
select 'Without discount' AS Criteria, code, SP as order_price
from promocodes as p
join (
    select promocode_id, SUM(order_price) as SP
    from client_promocode_usages
    group by promocode_id
    order by SP desc
    limit 1
) as client_orders_sum on client_orders_sum.promocode_id = p.id
union
select 'With discount' AS Criteria, code, SPD
from promocodes as p
join (
    select promocode_id, SUM(order_price) as SP, SUM(order_price - order_discount) as SPD
    from client_promocode_usages
    group by promocode_id
    order by SP desc
    limit 1
) as client_orders_sum on client_orders_sum.promocode_id = p.id;

-- 13 Инструкция SELECT, использующая вложенные подзапросы с уровнем вложенности 3.
-- вернет клиента, которвый использовал популярный (больше 4900 использований) промокод для первого заказа
select c.id, c.last_name, c.first_name
from clients as c
where c.id = (
    select client_id
    from client_promocode_usages
    where promocode_id in (
        select id
        from promocodes
        where count > 4900 and for_first_order
        )
    limit 1
    )
;

-- 14. Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY, но без предложения HAVING.
-- клиенты, у которых все заказы были совершены в последние 100 дней + средняя цена заказа + их количество
select client_id, avg(order_price) as avg_order_price, count(*) as orders_count
from client_promocode_usages as cpu
where added_at > current_date - 100
group by client_id;

-- 15 Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY и предложения HAVING.
select client_id, sum(order_price) as sum_order_price
from client_promocode_usages as cpu
group by client_id
having avg(order_price) > 5000;

-- 16 Однострочная инструкция INSERT, выполняющая вставку в таблицу одной строки значений.
insert into client_promocode_usages (promocode_id, client_id, order_price, order_discount)
values (501, 43, 5000, 150);

-- 17 Многострочная инструкция INSERT, выполняющая вставку в таблицу результирующего набора данных вложенного подзапроса.
-- вставляем 5 использований промокода с самой большой скидкой
insert into client_promocode_usages (promocode_id, client_id, order_price, order_discount)
select (
    select id
    from promocodes
    order by price desc
    limit 1
            ) as p_id, client_id, order_price, order_discount
from client_promocode_usages
limit 5;

-- 18 Простая инструкция UPDATE.
update clients
set age = age - 20
where age > 80;

-- 19 Инструкция UPDATE со скалярным подзапросом в предложении SET.
update coupons
set date_start = date_start + interval '20 years',
    date_end = (
        select max(date_end)
        from coupons
    ) + interval '20 years'
where date_start < date '1990-01-01';

-- 20 Простая инструкция DELETE
delete from clients
where comment like 'агрессивный%' and rating = 0;

-- 21 Инструкция DELETE с коррелированным подзапросом в предложении WHERE.
-- удалить строки где действие купона закончилось 1990-01-01
delete from client_promocode_usages
where promocode_id in (
    select p.id
    from promocodes p join coupons c on p.coupon_id = c.id
    where date_end < date '1990-01-01'
    );

-- 22 Инструкция SELECT, использующая простое обобщенное табличное выражение
-- выбираем использованные промокоды крутыми клиентами
with top_clients as (
    select id
    from clients
    where rating >= 9
), top_last_usages as (
    select promocode_id as id
    from client_promocode_usages
    where client_id in (select id from top_clients)
    group by promocode_id
)
select p.code, p.price
from promocodes as p
where p.id in (select id from top_last_usages);

-- 23 Инструкция SELECT, использующая рекурсивное обобщенное табличное выражение.
-- получаем сумму скидки по клиенту после каждого заказа и выводим сам номер заказа
with recursive first_order_promos (promo_id, promo_limit, discount, order_num) as (
    select p.id, p."limit", p.price, (1) as order_num
    from promocodes as p
    where p."limit" < 5
    union all
    select promo_id, promo_limit, (discount / order_num) + discount, order_num + 1
    from first_order_promos
    where order_num < promo_limit and promo_limit < 5
)
select promo_id, discount, promo_limit, order_num
from first_order_promos;

-- 24 Оконные функции. Использование конструкций MIN/MAX/AVG OVER()
-- выводятся скидки по заказам для каждого клиента + средняя скидка для этого клиента
select id, client_id, order_discount, avg(order_discount) over (partition by client_id) as discount_avg_for_client
from client_promocode_usages;

-- 25 Оконные фнкции для устранения дублей
-- выводятся номер заказа клиента, скидки по заказам для каждого клиента + средняя скидка для этого клиента
select row_number() over (partition by client_id) as order_num, client_id, order_discount, avg(order_discount) over (partition by client_id) as discount_avg_for_client
from client_promocode_usages;

-- защита
select c.id, c.first_name, c.last_name, c.age
from clients as c
    inner join client_promocode_usages cpu on c.id = cpu.client_id
    inner join promocodes p on cpu.promocode_id = p.id
where p.price < 1000 and p.count < p."limit" and c.age = (
    select min(age)
    from clients
    )
;