# Makefile
SHELL := /bin/bash

# ========= Config por defecto =========
# ENV: environment de PlatformIO (cámbialo a esp32dev-arduino cuando uses el "dev")
ENV       ?= esp32s3-arduino
BAUD      ?= 115200
DURATION  ?= 10                   # segundos de captura
LOGDIR    ?= logs
CSV_RAW   ?= $(LOGDIR)/filters_compare.csv
CSV_CLEAN ?= $(LOGDIR)/filters_clean.csv
PYSCRIPT  ?= plot_filters.py      # script de Python para graficar
PLOT_SH   ?= ./plot.sh            # script que limpia/asegura cabecera + llama a plot

# Puerto: intenta by-id y si no, cae a ACM0
PORT ?= $(shell ls /dev/serial/by-id/* 2>/dev/null | head -n1)
ifeq ($(PORT),)
  PORT := /dev/ttyACM0
endif

# ======== Targets ========
.PHONY: all build flash monitor log plot flashlog venv deps clean s3 dev

all: build

build:
	@echo "==> Compilando ($(ENV))"
	pio run -e $(ENV)

flash:
	@echo "==> Flasheando ($(ENV)) en $(PORT)"
	pio run -e $(ENV) -t upload --upload-port $(PORT)

monitor:
	@echo "==> Monitor en $(PORT) @ $(BAUD)"
	pio device monitor -p $(PORT) -b $(BAUD)

log: | $(LOGDIR)
	@echo "==> Capturando $(DURATION)s desde $(PORT) a $(CSV_RAW)"
	timeout $(DURATION)s pio device monitor -p $(PORT) -b $(BAUD) | tee $(CSV_RAW) >/dev/null
	@echo "==> Log guardado en $(CSV_RAW)"

plot:
	@echo "==> Limpiando CSV y graficando"
	$(PLOT_SH) $(CSV_RAW)

flashlog: flash log plot
	@echo "==> Listo."

# Conveniencia para cambiar de environment
s3:
	@$(MAKE) ENV=esp32s3-arduino $(MAKECMDGOALS)

dev:
	@$(MAKE) ENV=esp32dev-arduino $(MAKECMDGOALS)

# ======== Python venv y dependencias ========
VENV      ?= .venv
PYTHON    ?= $(VENV)/bin/python
PIP       ?= $(VENV)/bin/pip

venv:
	@test -d $(VENV) || (python3 -m venv $(VENV) && echo "VENV creado en $(VENV)")
	@echo "Activación: source $(VENV)/bin/activate"

deps: venv
	$(PIP) install --upgrade pip
	$(PIP) install pandas matplotlib numpy

$(LOGDIR):
	mkdir -p $(LOGDIR)

clean:
	@echo "==> Limpiando build"
	pio run -t clean
