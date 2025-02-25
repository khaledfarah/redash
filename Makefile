.PHONY: compose_build up test_db create_database clean down bundle tests lint backend-unit-tests frontend-unit-tests test build watch start redis-cli bash

compose_build:
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build

up:
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose up -d --build

test_db:
	@for i in `seq 1 5`; do \
		if (docker-compose exec postgres sh -c 'psql -U postgres -c "select 1;"' 2>&1 > /dev/null) then break; \
		else echo "postgres initializing..."; sleep 5; fi \
	done
	docker-compose exec postgres sh -c 'psql -U postgres -c "drop database if exists tests;" && psql -U postgres -c "create database tests;"'

create_database:
	docker-compose run server create_db

clean:
	docker-compose down && docker-compose rm

down:
	docker-compose down

bundle:
	docker-compose run server bin/bundle-extensions

tests:
	docker-compose run server tests

lint:
	./bin/flake8_tests.sh

backend-unit-tests: up test_db
	docker-compose run --rm --name tests server tests

frontend-unit-tests: bundle
	CYPRESS_INSTALL_BINARY=0 PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 yarn --frozen-lockfile
	yarn bundle
	yarn test

test: lint backend-unit-tests frontend-unit-tests

build: bundle
	yarn build

watch: bundle
	yarn watch

start: bundle
	yarn start

redis-cli:
	docker-compose run --rm redis redis-cli -h redis

bash:
	docker-compose run --rm server bash

build_stg:
	docker build -t careem-redash . &&\
	docker tag careem-redash 848569320300.dkr.ecr.eu-west-1.amazonaws.com/careem-redash:latest &&\
	docker push 848569320300.dkr.ecr.eu-west-1.amazonaws.com/careem-redash:latest

build_prod:
	docker build --network=host -t careem-redash . &&\
	docker tag careem-redash 848569320300.dkr.ecr.eu-west-1.amazonaws.com/careem-redash:prod &&\
	docker push 848569320300.dkr.ecr.eu-west-1.amazonaws.com/careem-redash:prod &&\
	docker tag careem-redash 848569320300.dkr.ecr.eu-west-1.amazonaws.com/careem-redash:stg &&\
	docker push 848569320300.dkr.ecr.eu-west-1.amazonaws.com/careem-redash:stg

build_karl_stg:
	docker build -t karllchris/redash-stg . && docker push karllchris/redash-stg

build_karl:
	docker build -t karllchris/redash . && docker push karllchris/redash
