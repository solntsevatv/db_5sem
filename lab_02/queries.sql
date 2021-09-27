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
                        where rating < 5 and comment like '%агрессивный%')

-- 5 Инструкция SELECT, использующая предикат EXISTS с вложенным подзапросом
select c.id, c.last_name, c.first_name
from marketing.clients as c
where exists(select c.id
    from marketing.clients left join marketing.client_promocode_usages as cpu
    on c.id = cpu.client_id
    where cpu.client_id is not null)

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
-- TODO как это работает?? никак не работает
SELECT id, order_price,
       CAST(order_price - order_discount * 1.0) AS SR INTO BestSelling
FROM marketing.client_promocode_usages
where added_at > current_date - 15;

-- 12 Инструкция SELECT, использующая вложенные коррелированные
-- подзапросы в качестве производных таблиц в предложении FROM.
select 'Without discount' AS Criteria, code, SP as sum
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
select client_id, avg(order_price)
from client_promocode_usages as cpu
where added_at > current_date - 100
group by client_id;

-- 15 Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY и предложения HAVING.
select client_id, avg(order_price)
from client_promocode_usages as cpu
group by client_id
having sum(order_price) > 10000;

-- 16 Однострочная инструкция INSERT, выполняющая вставку в таблицу одной строки значений.
insert into client_promocode_usages (promocode_id, client_id, order_price, order_discount)
values (501, 43, 5000, 150);

-- 17 Многострочная инструкция INSERT, выполняющая вставку в таблицу результирующего набора данных вложенного подзапроса.
insert into client_promocode_usages (promocode_id, client_id, order_price, order_discount)
select (
    select id
    from promocodes
    order by price desc
    limit 1
            ), client_id, order_price, order_discount
from client_promocode_usages
where promocode_id = id;

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
where comment = 'агрессивный' and rating = 0;

-- 21 Инструкция DELETE с коррелированным подзапросом в предложении WHERE.
delete from client_promocode_usages
where promocode_id in (
    select p.id
    from promocodes p join coupons c on p.coupon_id = c.id
    where date_end < date '1990-01-01'
    );

-- 22 Инструкция SELECT, использующая простое обобщенное табличное выражение
with top_clients as (
    select id
    from clients
    where rating >= 9
)
select c.last_name, c.first_name, c.rating
from clients as c
where c.id in (select id from top_clients);

-- 23 Инструкция SELECT, использующая рекурсивное обобщенное табличное выражение.
with recursive first_order_promos (promo_id, discount, promo_limit) as (
    select p.id, p.price, p."limit"
    from promocodes as p
    where p.for_first_order and p.price > 2000
    union all
    select cpu.promocode_id, cpu.order_discount, 1
    from client_promocode_usages as cpu inner join first_order_promos as f
    on f.promo_id = cpu.promocode_id and f.discount = cpu.order_discount
)
select promo_id, discount, promo_limit
from first_order_promos;

-- 24 Оконные функции. Использование конструкций MIN/MAX/AVG OVER()
select id, client_id, order_discount, avg(order_discount) over (partition by client_id) as discount_avg_for_client
from client_promocode_usages;

-- 25 Оконные фнкции для устранения дублей
select row_number() over (partition by client_id), client_id, order_discount, avg(order_discount) over (partition by client_id) as discount_avg_for_client
from client_promocode_usages;