# poma
**Po**stgresql projects **Ma**kefile

[poma](https://github.com/pomasql/poma) предназначен для облегчения загрузки в БД postgresql SQL-кода (DDL и DML)
 в проектах, где такой код разделяется на несколько файлов и каталогов. Далее такие каталоги называются "пакеты".

Если SQL-код размещен в пакетах под общим корнем `sql/`, то [poma](https://github.com/pomasql/poma) - один из пакетов в общем списке.

## Project tree

Структура проектов, использующих [poma](https://github.com/pomasql/poma), имеет вид:

```
poma-sample
├── .env - конфигурация проекта, создается `make config`
├── Makefile - основной Makefile проекта, имеет строку `include sql/poma/Makefile`
└── sql
    ├── poma - клон проекта poma (без изменений)
    │   ├── 00_cleanup.sql
    │   ├── ...
    │   ├── Makefile - Makefile с рецептами poma
    │   └── README.md
    └── sample - другие sql-пакеты проекта
        ├── 00_cleanup.sql
```

## Usage

Т.к. порядок загрузки пакетов имеет значение и из одного комплекта пакетов могут загружаться в БД разные наборы,
 списки пакетов именуются и размещаются в основном Makefile проекта. Пример для списка с именем `all`:

```
%-all: POMA_PKG=sample1 sample2
```
В результате, для работы с этим списком пакетов, к целям ниже (кроме `config`) добавятся аналогичные с суффиксом `-all`.
 Если суффикс не указан, по умолчанию используется `%-default`. Пример - см. Makefile проекта
 [poma-sample](https://github.com/pomasql/poma-sample).

В результате `include sql/poma/Makefile`, основной Makefile проекта будет поддерживать следующие цели:

* `make config` - создать файл настроек (.env) всего проекта
* `make poma-install` - создать схему poma и выполнить рецепт `poma-create-default`
* `make poma-create[-default]` - первичное создание пакета
* `make poma-build[-default]` - сборка хранимого кода
* `make poma-test[-default]` - запуск тестов
* `make poma-recreate[-default]` - пересоздание пакетов со сборкой кода
* `make poma-drop[-default]` - удаление пакета
* `make poma-erase[-default]` - удаление пакета и его персистентных данных
* `make poma-uninstall` - выполнить рецепт `poma-drop-default` и удалить схему poma (схема pers удалена не будет)

## SQL filename

Файлы в пакетах имеют формат MM_описание[_once].sql, где

тип MM имеет значения:

* 00 - drop/erase: удаление связей текущей схемы с другими схемами
* 01 - erase: удаление защищенных объектов из других схем (wsd)
* 02 - drop/erase: удаление текущей схемы (02_drop)
* 10 - init: инициализация до создания схемы
* 11 - init: создание схемы, после выполнения 11* имя схемы из имени каталога добавится в путь поиска
* 12 - init: зависимости от других пакетов, создание доменов и типов
* 1[4-9] - общие файлы для init и make, код, не имеющий зависимостей от объектов, может использоваться при создании таблиц
* 2x - создание таблиц
* 3x - ф-и для представлений
* 4x - представления
* 5x - основной код функций
* 6x - код триггеров
* 7x - создание триггеров
* 8x - наполнение таблиц
* 9x - тесты

Если файл имеет суффикс `_once`, то он будет выполнен однократно.

## Препроцессинг

* [1,3,5,6]*.sql - замена `/($_$)($| +#?)/` на `\1\2 /* FILENAME:FILELINE */`
* [2,4,8]*_once.sql - в вызов таких файлов добавляется поддержка однократного запуска с WARNING при изменении md5
* 9*.sql - замена `/ -- BOT/` и `/; -- EOT/` на код поддержки тестов

## Алгоритм

### Процесс для каждого пакета

1. получить список файлов процесса
2. обработать файлы с ф-ями
3. обработать тесты
4. сгенерить вызов для файлов *_once.sql

### Общий процесс

1. получить список пакетов
2. если recreate
   1. процесс drop для каждого пакета в обратном порядке
   2. процесс create для каждого пакета
   3. собрать инклюды в build.sql
3. иначе
   1. процесс для каждого пакета
   2. собрать инклюды в build.sql
4. запустить build.sql

## Примеры
```
make clean poma-build POMA_PKG=
make clean poma-build POMA_PKG=sample

```
Для разработчика poma могут быть полезны команды из каталога poma:
```
make poma-clean .build/create.psql POMA_PKG=poma SQL_ROOT=.. MASK=[1-9]?_*.sql
make poma-clean .build/drop.psql POMA_PKG=poma SQL_ROOT=.. MASK="00_*.sql 02_*.sql"
```


## TODO

* [x] creatif (не пытаться создавать существующий пакет)
* [x] доработать log()
* [x] psql в docker
* [ ] в deps проверять psql
* [ ] поддержка make v3.81
* [ ] сделать тест работы make
* [ ] если awk ничего не поменял - вызвать исходник из sql/
* [ ] `make update` - если пакета нет, create, иначе - build
* [ ] поддержка go-bindata

## License

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2010-2018 Tender.Pro team <it@tender.pro>
Copyright (c) 2018 Aleksei Kovrizhkin <lekovr+poma@gmail.com>
