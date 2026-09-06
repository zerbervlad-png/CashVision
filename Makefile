.PHONY: help bootstrap dev test build archive release clean backend backend-test lint

help:
	@echo "CashVision Makefile"
	@echo "  make bootstrap  — первичная настройка проекта (Mac)"
	@echo "  make dev        — собрать и запустить в Simulator"
	@echo "  make test       — unit и UI тесты"
	@echo "  make build      — сборка (Debug по умолчанию, CONFIG=Release для релиза)"
	@echo "  make archive    — архив для App Store"
	@echo "  make release    — экспорт IPA"
	@echo "  make clean      — очистка артефактов"
	@echo "  make backend    — запустить backend (docker compose up)"
	@echo "  make backend-test — тесты backend"
	@echo "  make lint       — lint"

bootstrap:
	./scripts/bootstrap.sh

dev:
	./scripts/dev.sh

test:
	./scripts/test.sh

build:
	./scripts/build.sh $(CONFIG)

archive:
	./scripts/archive.sh

release:
	./scripts/release.sh

clean:
	./scripts/clean.sh

backend:
	cd backend && docker compose up -d --build

backend-test:
	cd backend && docker compose run --rm api python -m pytest -q

lint:
	@if command -v swiftlint >/dev/null 2>&1; then swiftlint; else echo "SwiftLint не установлен"; fi
	cd backend && ruff check . || true
