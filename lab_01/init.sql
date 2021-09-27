DROP SCHEMA IF EXISTS marketing CASCADE ;
CREATE SCHEMA marketing

create table marketing.coupons
(
    id           serial                                   not null
        constraint coupons_pk
            primary key,
    active       boolean     default true                  not null,
    description  varchar,
    name         varchar(30) default ''::character varying not null,
    source       char[2]                                      not null,
    max_discount integer     default 0,
    min_price    integer     default 0                     not null,
    date_start   date,
    date_end     date
);

create table marketing.promocodes
(
    id              serial                                   not null
        constraint promocodes_pk
            primary key,
    coupon_id       integer                                   not null,
    code            varchar(30) default ''::character varying not null,
    price           integer     default 0                     not null,
    "limit"         integer,
    count           integer     default 0                     not null,
    email           varchar(50),
    company         varchar(70),
    for_first_order boolean     default false,
    foreign key (coupon_id) references marketing.coupons(id) on delete cascade
);

create table marketing.clients
(
    id               serial                                   not null
        constraint clients_pk
            primary key,
    active           boolean     default true                  not null,
    comment          varchar,
    rating           integer     default 5                     not null,
    last_name        varchar(30) default ''::character varying not null,
    first_name       varchar(30) default ''::character varying not null,
    middle_name      varchar(30),
    age              integer                                   not null,
    orders_count     integer     default 0                     not null,
    first_order_date date,
    last_order_date  date
);

create table marketing.client_promocode_usages
(
    id           serial                        not null
        constraint client_coupon_usages_pk
            primary key,
    promocode_id integer                        not null,
    client_id    integer                        not null,
    added_at     date default CURRENT_TIMESTAMP not null,
    order_price integer     default 0 not null,
    order_discount    integer,
    foreign key (client_id) references marketing.clients(id) on delete cascade,
    foreign key (promocode_id) references marketing.promocodes(id) on delete cascade
);