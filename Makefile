IMAGE=snmpsim:dev
DATASETS=$(PWD)/datasets
CONFIG=$(PWD)/config
SCRIPTS=$(PWD)/scripts

build:
	docker build -t $(IMAGE) .

run:
	docker run --name snmpmini --rm \
		-p 161:161/udp \
		-v $(DATASETS):/data:ro \
		$(IMAGE)

run-multi:
	docker run --name snmpmini --rm \
		-p 161:161/udp \
		-v $(DATASETS):/data:ro \
		-v $(CONFIG):/app/config:ro \
		$(IMAGE) \
		--args-from-file=/app/config/agents.txt --data-dir=/data

run-v3:
	docker run --name snmpmini --rm \
		-p 161:161/udp \
		-v $(DATASETS):/data:ro \
		$(IMAGE) \
		--data-dir=/data \
		--v3-user=snmpsim \
		--v3-auth-key=authpassword \
		--v3-priv-key=privpassword \
		--v3-auth-proto=SHA \
		--v3-priv-proto=AES

logs:
	docker logs -f snmpmini

stop:
	docker stop snmpmini || true

smoke:
	$(MAKE) run &
	sleep 2
	python3 $(SCRIPTS)/smoke_udp.py 127.0.0.1 161 || (docker stop snmpmini; exit 1)
	docker stop snmpmini

clean:
	docker rm -f snmpmini 2>/dev/null || true
	docker rmi -f $(IMAGE) 2>/dev/null || true
