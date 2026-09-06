# Запуск CashVision на Mac — пошаговая инструкция

## Что нужно установить (один раз)

### 1. Xcode 15.4+
- Открой **App Store** на Mac
- Найди **Xcode** → установи (около 10 ГБ, занимает время)
- После установки запусти Xcode один раз и прими лицензию

### 2. Command Line Tools
```bash
xcode-select --install
```
Во всплывающем окне нажми «Установить».

### 3. Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
После установки добавь brew в PATH (подскажет сам установщик).

### 4. XcodeGen
```bash
brew install xcodegen
```

### 5. Docker Desktop (для backend, опционально)
- Скачай с https://docker.com/products/docker-desktop
- Установи и запусти Docker Desktop

---

## Запуск iOS-приложения (основное)

### Шаг 1. Клонировать репозиторий
```bash
git clone https://github.com/zerbervlad-png/CashVision.git
cd CashVision
```

### Шаг 2. Запустить одной командой
```bash
chmod +x run-mac.sh
./run-mac.sh
```

**Что сделает скрипт автоматически:**
1. ✅ Проверит macOS
2. ✅ Проверит Xcode и версию Swift
3. ✅ Проверит Homebrew
4. ✅ Установит XcodeGen (если нет)
5. ✅ Сгенерирует `CashVision.xcodeproj` из `project.yml`
6. ✅ Найдет или создаст iPhone Simulator
7. ✅ Соберет приложение (Debug)
8. ✅ Установит в Simulator
9. ✅ Запустит приложение

### Альтернатива — по шагам
```bash
./scripts/bootstrap.sh    # первичная настройка + генерация проекта
./scripts/dev.sh          # сборка + запуск в Simulator
./scripts/test.sh         # unit + UI тесты
./scripts/build.sh        # сборка (Debug)
./scripts/build.sh Release # сборка (Release)
./scripts/archive.sh      # архив для App Store
./scripts/release.sh      # экспорт IPA
./scripts/clean.sh        # очистка артефактов
```

### Через Makefile
```bash
make bootstrap
make dev
make test
make build
make clean
```

---

## Запуск backend (опционально)

### Через Docker (рекомендуется)
```bash
cd backend
cp .env.example .env
docker compose up -d --build
```

Проверка:
```bash
curl http://localhost:8000/health
# → {"status":"ok","version":"1.0.0",...}
```

Документация API: http://localhost:8000/api/v1/docs

### Без Docker (локальный Python)
```bash
cd backend
pip install fastapi uvicorn[standard] pydantic-settings sqlalchemy asyncpg redis prometheus-client slowapi
uvicorn api.main:app --reload --port 8000
```

### Тесты backend
```bash
cd backend
pip install pytest httpx
python -m pytest -q
```

### Нагрузочное тестирование
```bash
cd backend
pip install locust
locust -f tests/locustfile.py --host http://localhost:8000
# открыть http://localhost:8089
```

---

## Запуск тестов iOS

```bash
./scripts/test.sh
```

Или через Xcode:
1. Открой `CashVision.xcodeproj` в Xcode
2. `Cmd+U` — запустить тесты
3. `Cmd+Shift+K` — очистить
4. `Cmd+B` — собрать
5. `Cmd+R` — запустить

---

## Если что-то не работает

### «Xcode not found»
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### «Simulator not found»
```bash
xcrun simctl create "iPhone 15" "com.apple.CoreSimulator.SimDeviceType.iPhone-15" "com.apple.CoreSimulator.SimRuntime.iOS-17-0"
```

### «xcodegen: command not found»
```bash
brew install xcodegen
```

### Очистить и пересобрать
```bash
./scripts/clean.sh
./scripts/bootstrap.sh
./scripts/dev.sh
```

### Камера не работает в Simulator
Симулятор не имеет реальной камеры. Для тестирования CV:
1. Открой Simulator → Device → Camera → использовать встроенную
2. Или тестируй на реальном iPhone (подключи по USB, выбери в Xcode как target)

---

## Структура веток

| Ветка | Назначение |
|-------|-----------|
| `main` | Стабильный релиз |
| `develop` | Интеграция и тестирование |
| `feature/ios-app` | Разработка iOS-кода |
| `feature/backend` | Разработка backend |
| `feature/ml-models` | ML-модели распознавания |
| `feature/tests` | Тесты |

Переключение:
```bash
git checkout develop
git pull origin develop
```

---

## Минимальные требования

| Компонент | Версия |
|-----------|--------|
| macOS | 14.0+ (Sonoma) |
| Xcode | 15.4+ |
| iOS deployment target | 17.0+ |
| Swift | 5.10+ |
| Docker (для backend) | 24+ |
| RAM | 8 ГБ минимум, 16 ГБ рекомендуется |

---

## Быстрая шпаргалка

```bash
# Клонировать и запустить
git clone https://github.com/zerbervlad-png/CashVision.git
cd CashVision
chmod +x setup-mac.sh
./setup-mac.sh

# Обновить после изменений (я делаю push → ты делаешь pull)
git pull origin main
# post-merge hook автоматически перегенерирует .xcodeproj
# В Xcode: Cmd+R для пересборки

# Или одной командой из любого места:
cv-sync

# Запустить тесты
./scripts/test.sh

# Открыть в Xcode
open CashVision.xcodeproj
```

---

## Авто-синхронизация с GitHub (AI workflow)

После `setup-mac.sh` Git hooks уже установлены. Дополнительно:

### Вариант 1: Фоновый авто-pull (пока ты тестируешь UI)
```bash
./scripts/watch-git.sh
```
Скрипт каждые 30 секунд проверяет GitHub на новые коммиты. Если я делаю push:
1. Автоматически делает `git pull`
2. Перегенерирует `.xcodeproj`
3. Выводит уведомление в Terminal
4. Ты нажимаешь **Cmd+R** в Xcode → пересборка с актуальным кодом

### Вариант 2: Ручной pull по необходимости
```bash
git pull origin main
# Hook автоматически перегенерирует проект
# Cmd+R в Xcode
```

### Вариант 3: Запуск с авто-pull + Xcode + Simulator
```bash
./sync-and-run.sh
```
Делает всё за один запуск:
1. `git pull` из нужной ветки
2. Перегенерация `.xcodeproj`
3. Сборка + запуск в Simulator
4. Открытие Xcode для редактирования

С watch-режимом:
```bash
./sync-and-run.sh --watch
```

### Полный workflow для итеративной разработки
1. На Mac: `./sync-and-run.sh` (один раз)
2. Xcode открывается с проектом
3. Simulator запускается с приложением
4. Ты тестируешь UI, сообщаешь мне о проблемах
5. Я вношу правки и делаю `git push origin main`
6. На Mac срабатывает авто-pull (если запущен `watch-git.sh`)
7. В Terminal появляется уведомление о новых изменениях
8. В Xcode: **Cmd+R** → пересборка с актуальным кодом
9. Повторять с шага 4
