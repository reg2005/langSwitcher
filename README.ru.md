# LangSwitcher

[English](README.md) | **Русский**

**Бесплатный конвертер раскладки клавиатуры для macOS с открытым исходным кодом.**

Набрали текст не в той раскладке? Нажмите горячую клавишу — LangSwitcher мгновенно переведёт `ghbdtn` в `привет`. Больше не нужно перепечатывать.

Открытая альтернатива [Caramba Switcher](https://caramba-switcher.com/mac) и [Punto Switcher](https://yandex.ru/soft/punto/).

[![Build](https://github.com/reg2005/langSwitcher/actions/workflows/build.yml/badge.svg)](https://github.com/reg2005/langSwitcher/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-brightgreen.svg)](https://www.apple.com/macos/)
[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org/)

> Если LangSwitcher вам полезен, поддержите проект — [задонатить](#пожертвования)! Любая помощь ценна!

**[Документация](https://reg2005.github.io/langSwitcher/ru)** | **[Documentation (EN)](https://reg2005.github.io/langSwitcher/en)**

## Демо

https://github.com/reg2005/langSwitcher/raw/main/screenshots/langSwitch.mp4

## Скриншот

![Настройки LangSwitcher — вкладка General](screenshots/general.png)

## Возможности

- **Мгновенная конвертация** — выделите текст и нажмите горячую клавишу для конвертации между раскладками
- **Умная конвертация** — работает даже без ручного выделения текста:
  - **Жадная строка (по умолч.)** — выделяет до начала строки, находит границу неправильной раскладки, конвертирует только ошибочную часть
  - **Последнее слово** — автоматически выделяет и конвертирует только последнее набранное слово
  - **Выключено** — работает только с ручным выделением
- **Автоопределение** — автоматически определяет, в какой раскладке набран текст
- **Системные раскладки** — использует установленные в системе раскладки клавиатуры
- **Двойной Shift** — нажмите `⇧⇧` (Shift дважды быстро) для конвертации, или настройте свою комбинацию
- **Журнал конвертаций** — опционально сохраняет конвертации в локальную базу SQLite (отключено по умолчанию ради приватности). Просмотр и оценка записей (правильно/неправильно) для будущего обучения ML
- **Экспорт JSON** — экспорт журнала конвертаций для анализа данных или обучения моделей
- **Приложение в меню-баре** — тихо живёт в строке статуса, всегда готово к работе
- **5 раскладок** — английская, русская, немецкая, французская, испанская
- **Сохранение пунктуации** — `?`, `!`, `/` и другие знаки не меняются при конвертации
- **Ноль зависимостей** — чистый Swift, никаких внешних библиотек и словарей
- **Приватность** — данные не покидают Mac, никакой аналитики, никаких сетевых запросов
- **Открытый код** — лицензия MIT, контрибьюты приветствуются

## Как это работает

```
1. Вы набираете "ghbdtn" (хотели "привет", но была английская раскладка)
2. Выделяете текст (или просто нажмите горячую клавишу — Умная конвертация сама справится)
3. Нажимаете ⇧⇧ (двойной Shift)
4. Текст заменяется на "привет"
```

LangSwitcher маппит символы по **физическим позициям клавиш** на клавиатуре. Одна и та же клавиша даёт разные символы в зависимости от раскладки — LangSwitcher обращает этот маппинг.

## Скачать

### DMG (рекомендуется)

Перейдите в [Releases](https://github.com/reg2005/langSwitcher/releases/latest) и скачайте:

| Архитектура | Файл |
|---|---|
| **Apple Silicon (M1/M2/M3/M4)** | `LangSwitcher-*-arm64.dmg` |
| **Intel** | `LangSwitcher-*-x86_64.dmg` |
| **Universal (обе)** | `LangSwitcher-*-universal.dmg` |

1. Откройте DMG и перетащите **LangSwitcher** в **Программы**
2. Запустите LangSwitcher
3. Дайте разрешение **Accessibility** при запросе

### Сборка из исходников

#### Требования

- macOS 13.0 (Ventura) или новее
- Xcode 15.0 или новее

#### Шаги

```bash
# Клонируйте репозиторий
git clone https://github.com/reg2005/langSwitcher.git
cd langSwitcher

# Запустите тесты
xcodebuild test \
  -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Соберите (универсальный бинарник)
xcodebuild -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -configuration Release \
  -derivedDataPath build \
  -arch arm64 -arch x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

# Приложение: build/Build/Products/Release/LangSwitcher.app
```

Или откройте `LangSwitcher.xcodeproj` в Xcode и нажмите `⌘R`.

## Использование

### Базовый процесс

1. **Набираете текст** в любом приложении
2. **Понимаете**, что была не та раскладка
3. **Нажимаете** `⇧⇧` (двойной Shift) — Умная конвертация сама выделяет и конвертирует
4. Или **выделяете** текст вручную, затем нажимаете горячую клавишу
5. Текст **мгновенно конвертируется** в правильную раскладку

### Режимы Умной конвертации

| Режим | Поведение |
|-------|-----------|
| **Жадная строка** (по умолч.) | Выделяет до начала строки, находит где начинается неправильная раскладка, конвертирует всю ошибочную фразу. `"ghbdtn rfr ltkf lheu"` -> `"привет как дела друг"` |
| **Последнее слово** | Выделяет только последнее слово перед курсором, конвертирует если похоже на неправильную раскладку |
| **Выключено** | Работает только с ручным выделением текста |

### Меню-бар

LangSwitcher живёт в строке меню с иконкой клавиатуры. Нажмите для:

- Ручной конвертации выделенного текста
- Просмотра активных раскладок
- Просмотра статистики конвертаций
- Открытия настроек
- Выхода из приложения

### Настройки

Откройте из иконки в меню-баре -> **Settings** (или `⌘,`):

| Вкладка | Описание |
|---------|----------|
| **General** | Запуск при входе, звуки, уведомления, режим Умной конвертации, режим переключения раскладки |
| **Layouts** | Просмотр и обновление обнаруженных раскладок |
| **Hotkey** | Переключение двойного Shift или запись своей комбинации |
| **Permissions** | Проверка и выдача доступа Accessibility |
| **Log** | Просмотр истории конвертаций, оценка записей, экспорт в JSON |

### Журнал конвертаций

Журнал конвертаций **отключён по умолчанию** ради приватности. Включить можно в **Settings -> General -> Conversion Logging**.

При включении конвертации сохраняются в локальную базу SQLite (`~/Library/Application Support/LangSwitcher/conversion_log.sqlite`). Можно настроить максимальное количество записей (по умолчанию: 100, или 0 — без ограничений). Во вкладке **Log** можно:

- Просматривать все конвертации (вход -> выход, раскладки, режим, время)
- Оценивать каждую как правильную или неправильную (три состояния: без оценки / правильно / неправильно)
- Экспортировать данные в JSON для обучения ML или анализа
- Удалять отдельные записи или очищать весь журнал

**Данные никогда не покидают ваш Mac.** Журнал хранится исключительно локально и никуда не отправляется.

## Поддерживаемые раскладки

LangSwitcher определяет раскладки из **Системные настройки > Клавиатура > Источники ввода**. На данный момент:

| Раскладка | Код языка | Физическая раскладка |
|-----------|-----------|---------------------|
| U.S. (QWERTY) | `en` | QWERTY |
| ABC | `en` | QWERTY |
| Русская | `ru` | ЙЦУКЕН |
| Немецкая | `de` | QWERTZ |
| Французская | `fr` | AZERTY |
| Испанская | `es` | QWERTY (Spanish) |

Добавить новую раскладку просто — см. [Контрибьюты](#контрибьюты).

## Архитектура

```
LangSwitcher/
├── Sources/
│   ├── App/
│   │   ├── LangSwitcherApp.swift       # Точка входа SwiftUI App
│   │   ├── AppDelegate.swift           # Жизненный цикл, горячие клавиши, оркестрация
│   │   └── StatusBarController.swift   # Иконка и меню в строке меню
│   ├── Views/
│   │   ├── SettingsView.swift          # Окно настроек (5 вкладок)
│   │   ├── ConversionLogView.swift     # Журнал конвертаций с оценками
│   │   ├── HotkeyRecorderView.swift    # Запись горячей клавиши
│   │   ├── AboutView.swift             # Окно «О программе»
│   │   └── PermissionsView.swift       # Права Accessibility
│   ├── Services/
│   │   ├── LayoutMapper.swift          # Движок маппинга символов
│   │   ├── KeyboardLayoutDetector.swift # Определение раскладок (Carbon TIS)
│   │   ├── TextConverter.swift         # Оркестратор конвертации + жадный алгоритм
│   │   ├── ConversionLogStore.swift    # Хранилище журнала на SQLite
│   │   ├── HotkeyManager.swift         # Глобальные горячие клавиши
│   │   ├── AccessibilityService.swift  # Замена текста через буфер обмена
│   │   └── SettingsManager.swift       # Сохранение настроек в UserDefaults
│   ├── Localization/
│   │   ├── LocalizationManager.swift   # Движок i18n (runtime)
│   │   ├── Strings_en.swift            # Английские строки (~113 ключей)
│   │   └── Strings_ru.swift            # Русские строки
│   └── Models/
│       ├── KeyboardLayout.swift        # Модель раскладки и карты символов
│       └── ConversionLog.swift         # Модель записи журнала
├── Resources/
│   └── Assets.xcassets                 # Иконки и цвета
├── LangSwitcherTests/
│   ├── LayoutMapperTests.swift         # 58 тестов маппинга
│   └── TextConverterTests.swift        # 35 тестов конвертера
├── .github/workflows/
│   ├── build.yml                       # CI: тесты + сборка DMG (Intel/ARM/Universal) + релиз
│   └── pages.yml                       # Деплой GitHub Pages
├── screenshots/
│   ├── general.png                     # Скриншот вкладки General
│   └── langSwitch.mp4                  # Демо-видео
└── docs/                              # Сайт документации (Docus v4)
    ├── nuxt.config.ts                  # Конфигурация Nuxt/Docus с i18n
    ├── app.config.ts                   # Конфигурация приложения (header, SEO, socials)
    ├── package.json                    # Зависимости Docus
    └── content/
        ├── en/                         # Английская документация
        └── ru/                         # Русская документация
```

### Как работает конвертация

```
Вход: "ghbdtn" (набрано на раскладке US, хотели русскую)

1. Определяем исходную раскладку -> "US" (символы совпадают с картой US)
2. Для каждого символа находим физическую позицию клавиши:
   g -> клавиша [0x05]
   h -> клавиша [0x04]
   ...
3. Маппим физическую клавишу на целевую раскладку (русскую):
   [0x05] -> п
   [0x04] -> р
   ...
4. Применяем сохранение пунктуации (не-буква -> не-буква остаётся)
5. Результат: "привет"
```

### Ключевые решения

- **Замена через буфер обмена**: Подход `⌘C` -> преобразование -> `⌘V` для максимальной совместимости с приложениями. Работает практически в любом текстовом поле.
- **Без CGEvent tap**: Вместо `CGEventTap` (требует специальных entitlements) используем `NSEvent.addGlobalMonitorForEvents` для горячих клавиш и `CGEvent` с `.hidSystemState` для симуляции клавиатуры.
- **Маппинг по физическим клавишам**: Символы сопоставляются через физическую позицию клавиши, а не через таблицы Unicode. Это надёжнее для нестандартных раскладок.
- **Без sandbox**: Приложению нужен доступ Accessibility, несовместимый с App Sandbox.
- **SQLite для журнала**: Прямой SQLite3 C API — без внешних зависимостей. Данные остаются локальными для приватности.
- **Двухпроходный жадный алгоритм**: Проход 1 проверяет всю строку целиком (все слова меняют скрипт). Проход 2 сканирует справа налево для смешанных строк. Порог 70% для неоднозначных случаев.

## Стек технологий

| Компонент | Технология |
|-----------|-----------|
| **Язык** | Swift 5 |
| **UI** | SwiftUI |
| **Платформа** | macOS 13+ (Ventura) |
| **Определение ввода** | Carbon (TISInputSource) |
| **Работа с текстом** | Accessibility API + Pasteboard |
| **Горячие клавиши** | NSEvent global monitor + CGEvent |
| **Настройки** | UserDefaults |
| **Журнал** | SQLite3 (C API, без зависимостей) |
| **Локализация** | Собственная runtime i18n (английский, русский) |
| **CI/CD** | GitHub Actions |
| **Дистрибуция** | DMG (Intel + ARM + Universal) через GitHub Releases |
| **Сайт** | GitHub Pages |
| **Тесты** | XCTest (93 теста) |

## Разрешения

LangSwitcher требует доступ **Accessibility** для:
- Чтения выделенного текста (через симуляцию `⌘C`)
- Замены текста (через симуляцию `⌘V`)

Выдайте доступ в **Системные настройки -> Конфиденциальность и безопасность -> Accessibility**.

Приложение **не**:
- Логирует нажатия клавиш
- Отправляет данные на серверы — **все данные остаются на вашем Mac**
- Обращается к файлам или сети
- Работает в фоне после выхода
- Собирает аналитику или телеметрию

**Журнал конвертаций отключён по умолчанию.** Если вы его включите, все данные хранятся локально в `~/Library/Application Support/LangSwitcher/`. Ничего никуда не отправляется.

## Контрибьюты

Контрибьюты приветствуются! Как добавить новую раскладку:

1. Откройте `LangSwitcher/Sources/Models/KeyboardLayout.swift`
2. Добавьте новое статическое свойство в `LayoutCharacterMap` с маппингом символов
3. Добавьте паттерн в массив `allMaps` (**порядок важен** — специфичные паттерны перед общими)
4. Добавьте тесты в `LangSwitcherTests/LayoutMapperTests.swift`
5. Запустите тесты: все 93+ должны проходить

```swift
// Пример: добавление итальянской раскладки
static let italian: [Character: Character] = {
    let qwerty  = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./...")
    let italian = Array("\\1234567890'ìqwertyuiopè+ùasdfghjklòàzxcvbnm,.-...")
    var map: [Character: Character] = [:]
    for i in 0..<min(qwerty.count, italian.count) {
        map[qwerty[i]] = italian[i]
    }
    return map
}()
```

### Добавление нового языка (i18n)

LangSwitcher использует собственную систему локализации — без `.lproj` / `.strings` файлов. Язык переключается в рантайме без перезапуска приложения.

1. **Скопируйте английский шаблон**:
   ```bash
   cp LangSwitcher/Sources/Localization/Strings_en.swift \
      LangSwitcher/Sources/Localization/Strings_xx.swift
   ```
   Замените `xx` на код языка (например `de`, `fr`, `es`).

2. **Переведите** все значения в словаре `strings`. Ключи остаются прежними — меняются только значения.

3. **Обновите `register()`** в конце нового файла:
   ```swift
   @MainActor static func register() {
       LocalizationManager.shared.register(language: "xx", strings: strings)
   }
   ```

4. **Зарегистрируйте новый файл** в `LangSwitcherApp.swift`:
   ```swift
   private func initializeLocalization() {
       Strings_en.register()
       Strings_ru.register()
       Strings_xx.register()  // <-- добавьте
   }
   ```

5. **Добавьте в список языков** в `LocalizationManager.swift`:
   ```swift
   let availableLanguages: [(code: String, name: String)] = [
       ("en", "English"),
       ("ru", "Русский"),
       ("xx", "Ваш Язык"),  // <-- добавьте
   ]
   ```

6. **Добавьте файл в Xcode-проект** — добавьте `PBXBuildFile`, `PBXFileReference`, в группу Localization и в `PBXSourcesBuildPhase` в `project.pbxproj`. Следуйте существующему формату PBX ID `E1000001...`.

7. **Запустите тесты** — все должны проходить.

Ключи строк используют префиксы пространств имён: `menu.*`, `settings.*`, `general.*`, `smartMode.*`, `layouts.*`, `hotkey.*`, `permissions.*`, `log.*`, `about.*`, `alert.*`, `common.*`.

### Подпись кода и нотаризация (CI/CD)

Релизные сборки могут быть подписаны сертификатом Apple Developer ID и нотаризованы через GitHub Actions. Без настроенных секретов сборки используют ad-hoc подпись (работает для локального использования, но macOS Gatekeeper будет предупреждать пользователей).

**Необходимые секреты** (Settings > Secrets and variables > Actions):

| Секрет | Описание |
|---|---|
| `MACOS_CERTIFICATE_P12` | Сертификат Developer ID Application, экспортированный как `.p12`, затем base64: `base64 -i cert.p12 \| pbcopy` |
| `MACOS_CERTIFICATE_PASSWORD` | Пароль, использованный при экспорте `.p12` |
| `MACOS_KEYCHAIN_PASSWORD` | Любая случайная строка (для временного CI keychain) |
| `MACOS_SIGNING_IDENTITY` | Полная строка идентификации, напр. `Developer ID Application: Your Name (TEAMID)` |

**Опциональные секреты** (для нотаризации — рекомендуется для публичного распространения):

| Секрет | Описание |
|---|---|
| `MACOS_NOTARIZATION_APPLE_ID` | Email вашего Apple ID |
| `MACOS_NOTARIZATION_PASSWORD` | App-specific password ([appleid.apple.com](https://appleid.apple.com) > Sign-In and Security > App-Specific Passwords) |
| `MACOS_NOTARIZATION_TEAM_ID` | 10-символьный Apple Developer Team ID |

**Как получить сертификат:**

1. Откройте Связку ключей (Keychain Access) на вашем Mac
2. В связке login найдите сертификат «Developer ID Application»
3. ПКМ > Экспортировать > сохраните как `.p12` с паролем
4. Закодируйте в base64: `base64 -i DeveloperID.p12 | pbcopy`
5. Вставьте результат в секрет `MACOS_CERTIFICATE_P12` на GitHub

**Поведение:**
- Если `MACOS_CERTIFICATE_P12` задан: сборки подписываются Developer ID + hardened runtime
- Если секреты нотаризации тоже заданы: DMG отправляются в Apple для нотаризации и stapling
- Если секреты не заданы: ad-hoc подпись (форки и PR работают без настройки)

### Разработка

```bash
# Клонируйте
git clone https://github.com/reg2005/langSwitcher.git
cd langSwitcher

# Запустите тесты (обязательно после каждого изменения)
xcodebuild test \
  -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Откройте в Xcode
open LangSwitcher.xcodeproj
```

См. [AGENTS.md](AGENTS.md) для правил AI-агентов и контрибьюторов.

## Пожертвования

LangSwitcher — бесплатное ПО с открытым исходным кодом. Если приложение вам полезно, любая помощь приветствуется и помогает развивать проект. Спасибо за поддержку!

### Для карт РФ

[Перевод через Т-Банк](https://www.tbank.ru/cf/66tz0unG7b7)

### Крипто

| Сеть | Адрес |
|------|-------|
| **Ethereum** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Tron** | `TDAyNkS36eKyqv9s4KQpu4ebWciQ2bqdW3` |
| **Bitcoin** | `bc1qtqm7rgma8dcgqc50lmzmyxn729yqrtf9zs7asx` |
| **Solana** | `A4jzTGxP7tbhyDFrcWJKdsA8v5xUwF6UzvC7RFmDRrfi` |
| **Linea** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Base** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **BNB Chain** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Sei** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Polygon** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **OP (Optimism)** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Arbitrum** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Fantom** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |

## Лицензия

[MIT License](LICENSE) — бесплатно для личного и коммерческого использования.

## Благодарности

Вдохновлён [Caramba Switcher](https://caramba-switcher.com/mac) и [Punto Switcher](https://yandex.ru/soft/punto/). Создан как бесплатная альтернатива с открытым кодом.
