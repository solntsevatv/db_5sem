from faker import Faker
from faker.providers import person
from faker.providers import date_time
from faker.providers import company
from random import randint
from random import uniform
from random import choice
import string
import random

MAX_N = 1000

source = ['{\"A\"}', '{\"S\"}', '{\"A\", \"S\"}']
sex = ['m', 'f']
bool_list = [True, False]
comments = ["vip-client", "не курит", "агрессивный", None]
description = ["корпоративный купон", "купон применяется только в Москве", "купон на первый заказ", None]
coupon_names = ["citycorp", "only_moscow", "first_order_coupon", "купон любимое_место", None]
rating = [1]

def generate_clients():
    faker = Faker('ru_RU')
    faker.add_provider(person)
    faker.add_provider(date_time)
    f = open('clients.csv', 'w')
    for i in range(MAX_N + 5):
        rating.append(randint(0, 10))
        client_sex = choice(sex)
        client_last_name = faker.last_name_female() if client_sex == 'f' else faker.last_name_male()
        client_first_name = faker.first_name_female() if client_sex == 'f' else faker.first_name_male()
        client_middle_name = faker.middle_name_female() if client_sex == 'f' else faker.middle_name_male()
        age = randint(3, 111)
        orders_count = randint(0, 1000)
        first_order_date = faker.date()
        last_order_date = faker.date()
        if first_order_date > last_order_date:
            first_order_date, last_order_date = last_order_date, first_order_date 
        line = "{0};{1};{2};{3};{4};{5};{6};{7};{8};{9}\n".format(
                                                  choice(bool_list),
                                                  choice(comments),
                                                  rating[i + 1],
                                                  client_last_name,
                                                  client_first_name,
                                                  client_middle_name,
                                                  age,
                                                  orders_count,
                                                  first_order_date,
                                                  last_order_date
                                                  )
        f.write(line)
    f.close()

def generate_coupons():
    faker = Faker('ru_RU')
    faker.add_provider(date_time)
    f = open('coupons.csv', 'w')
    for i in range(MAX_N + 5):
        max_discount = randint(500, 10000)
        min_price = randint(0, 1000)
        date_start = faker.date()
        date_end = faker.date()
        if date_start > date_end:
            date_start, date_end = date_end, date_start 
        line = "{0};{1};{2};{3};{4};{5};{6};{7}\n".format(
                                                  choice(bool_list),
                                                  choice(description),
                                                  choice(coupon_names),
                                                  choice(source),
                                                  max_discount,
                                                  min_price,
                                                  date_start,
                                                  date_end
                                                  )
        f.write(line)
    f.close()

def generate_promocodes():
    faker = Faker('ru_RU')
    faker.add_provider(company)
    faker.add_provider(date_time)
    f = open('promocodes.csv', 'w')
    for i in range(MAX_N):
        price = randint(50, 3000)
        limit = randint(50, 5000)
        count = randint(50, 5000)
        line = "{0};{1};{2};{3};{4};{5};{6};{7}\n".format(
                                                  randint(1, MAX_N - 1),
                                                  generate_alphanum_random_string(randint(4, 25)),
                                                  price,
                                                  limit,
                                                  count,
                                                  faker.email(),
                                                  faker.company(),
                                                  choice(bool_list)
                                                  )
        f.write(line)
    f.close()

def generate_client_promocode_usages():
    faker = Faker('ru_RU')
    faker.add_provider(date_time)
    f = open('client_promocode_usages.csv', 'w')
    for i in range(MAX_N + 5):
        client_id = randint(1, MAX_N - 1)
        order_price = randint(500, 10000)
        order_discount = randint(100, 3000)
        added_at = faker.date()
        if order_discount > order_price:
            order_discount, order_price = order_price, order_discount
        koef =  rating[client_id] / 10
        if order_discount  >= order_price * koef:
            order_discount = int(order_price * koef)
        line = "{0};{1};{2};{3};{4}\n".format(
                                                  randint(1, MAX_N - 1),
                                                  client_id,
                                                  added_at,
                                                  order_price,
                                                  order_discount
                                                  )
        f.write(line)
        print("client_id=", client_id, " rating=", rating[client_id])
    f.close()

def generate_alphanum_random_string(length):
    letters_and_digits = string.ascii_uppercase + string.digits
    rand_string = ''.join(random.sample(letters_and_digits, length))
    return rand_string

if __name__ == "__main__":
    generate_clients()
    generate_coupons()
    generate_promocodes()
    generate_client_promocode_usages()