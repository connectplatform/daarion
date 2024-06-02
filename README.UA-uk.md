
# Токени Екосистеми GreenFood

  

## DAAR Token (ERC-20)

DAAR - це токен, який використовується для купівлі та продажу продуктів у кооперативі органічних фермерів [GreenFood.live](https://greenfood.live). 0.5% від кожної транзакції надходить до гаманця для розподілу (walletD). Ці кошти щомісяця розподіляються між власниками токенів DAARION LP відповідно до їх частки у DAARION (вони отримують винагороду у вигляді DAAR). 

### Функціональність та Особливості  

1.  **Основні функції**
	-  **Токен ERC20**: DAAR є стандартним токеном ERC20.
	-  **Спалювання токенів**: DAAR токени можуть бути спалені, зменшуючи загальну кількість токенів в обігу.
	-  **Пауза**: Контракт може бути призупинений для запобігання транзакціям у разі потреби.

2.  **Розподіл комісій**
	-  **Транзакційна комісія**: 0.5% від кожної транзакції автоматично відправляється до walletD.
	-  **Розподіл серед учасників**: Кошти в walletD щомісяця розподіляються серед власників DAARION LP токенів.

3.  **Адміністрування та доступ**

	-  **Власник**: Власник контракту має особливі права, такі як встановлення комісії та розподіл ролей.
	-  **Роль розподільника**: Може бути призначений розподільник, який відповідає за розподіл DAAR токенів серед учасників.  

4.  **Інші функції**

	-  **Мінтинг (випуск) токенів**: Власник може випускати нові токени DAAR.
	-  **Виключення з комісії**: Деякі адреси можуть бути виключені з комісії.
	-  **Розподіл токенів**: Розподільник може розподіляти DAAR токени серед учасників.

### Діаграма

![DAAR Diagram](https://www.planttext.com/api/plantuml/svg/JO_12i8m38RlUOeSDz0Ny20RzYw8Fa2ecHIxjBGPmxUtbY8z1FuaNv8_KrPAkgqUpJpVBa4qaLKe4H8-CgSchxiK3R70phf8edK0uCVWyLmpFE4zaUIbb3IyMV8mGcqKe88T8An8QzX4_yXEthEQdbgOCNAoB4el1gW-kdk6emyVjCtuq5OSq8bJHxxo8qmip_Ba5m00)

### Як це працює?

  

1.  **Купівля та продаж продуктів**

	- Використовуйте DAAR токени для купівлі та продажу органічних продуктів у кооперативі.  

2.  **Транзакційна комісія**

	- Кожна транзакція стягує 0.5% комісії, яка відправляється до walletD.
	- Наприклад, якщо ви відправляєте 100 DAAR, 0.5 DAAR буде відправлено до walletD, а 99.5 DAAR до отримувача.

3.  **Розподіл винагороди**

	- Щомісяця кошти у walletD розподіляються серед власників DAARION LP токенів.
	- Винагорода у DAAR розподіляється відповідно до частки кожного учасника у DAARION.

  

### Приклад використання

1.  **Реєстрація учасника**

	- Фермер приєднується до кооперативу, отримує DAAR токени для купівлі/продажу продуктів.  

2.  **Транзакція**

	- Фермер А відправляє 100 DAAR фермеру Б за продукти.
	- Фермер Б отримує 99.5 DAAR, а 0.5 DAAR надходять до walletD.

3.  **Місячний розподіл**

	- Кошти у walletD розподіляються серед власників DAARION LP токенів, які застейкали їх у DAARDistributor.
  

### Розширена діаграма функціоналу DAAR:

![DAAR Diagram](https://www.planttext.com/api/plantuml/svg/XLJ1JkCm4BtxAqQSmYfquOgK5MK34XAeKYXdP999OwrZHnv7xFuzOzT9IWjQ7sBBy-RDi-SvD-IbysElXP2rjmvU25rQRjxDl2uLUQVUHbuBCN2AgjKWZOUpShskpa0Ib48K1MoTDDIYWqUxKpKKXH214Yv-GNaDFaMprja-1szpaBqTZJyNKdjGBIYw-rlhiS7cdY7tY1cXQT2T0wiu3Jfa7Ge30V0eKvtdSG1qgzUvtfuaXnc_54PD-2dvjzJrgAL7Q17N4GL5WiEF_HduLfGrh01-mjKbZsyO9W77D1SBzx7mBtM_IwtHb_cITdBW_vttinG-jsbYnvvK4CPzYlrEV3rlPeVjcGf5jBT_q11FG0CNQ1Ks89l68L6al1sTEQ5yuytic2uYztGnS_OPGZ1M93dmNifgPbG0BIQWII_DVbfYAurcvpkcd41f9rvaWdUIAginAn-UjzN3xSjsKxrMcyUx77hQhP8LOq8Osje1MfQ5ikwMKdFyi4DBR-PUVc76AIiq9ywJESCmbg_5gLtdmRR9Pnh3imWXaCkzy2kTM6Q6a-mdHRtqTHUQvvpyHtjBtF0t_10-0000)


## DAARDistributor Smart Contract

  

### Опис

  

`DAARDistributor` — це смарт-контракт, створений для керування стейкінгом і розподілом винагород у токенах DAAR і DAARION. Контракт також підтримує стейкінг з фіксованою річною процентною ставкою (APR), забезпечуючи стабільні винагороди для користувачів. Цей контракт пропонує гнучкість, безпеку та прозорість операцій.

  

### Особливості

-  **Стейкінг DAARION** — користувачі можуть стейкати токени DAARION для отримання винагород у DAAR.
-  **Анстейкінг DAARION** — користувачі можуть вивести свої стейкані токени DAARION та отримати накопичені винагороди.
-  **Отримання винагород** — користувачі можуть самостійно отримувати свої накопичені винагороди.
-  **Розподіл винагород** — власник контракту може розподілити накопичені винагороди серед користувачів.
-  **Стейкінг з APR** — користувачі можуть стейкати токени DAARION для отримання винагород із фіксованою річною процентною ставкою.
-  **Анстейкінг з APR** — користувачі можуть вивести свої APR стейкані токени DAARION та отримати APR винагороду.

  

### Переваги

  

-  **Безпека** — Контракт включає захист від повторних атак за допомогою ReentrancyGuard.
-  **Гнучкість** — Власник контракту може змінювати тривалість епох та інші параметри.
-  **Прозорість** — Всі важливі операції логуються через події, забезпечуючи прозорість усіх дій.
-  **Стабільні винагороди** — Можливість отримувати винагороди з фіксованою річною процентною ставкою (APR).
-  **Автоматичне розподілення** — Контракт автоматично керує винагородами та їх розподілом.

  

### Використання


1.  **Ініціалізація**:
	- Власник контракту викликає функцію `initialize`, щоб налаштувати початкові параметри.

2.  **Стейкінг DAARION**:
	- Користувачі викликають функцію `stakeDAARION`, щоб стейкати токени DAARION та отримувати винагороди.

3.  **Анстейкінг DAARION**:
	- Користувачі викликають функцію `unstakeDAARION` для виведення стейканих токенів.

4.  **Отримання винагород**:
	- Користувачі викликають функцію `claimRewards`, щоб отримати свої накопичені винагороди.

5.  **Розподіл винагород**:
	- Власник контракту викликає функцію `distributeDAAR`, щоб розподілити накопичені винагороди серед користувачів.

6.  **Стейкінг з APR**:
	- Користувачі викликають функцію `stakeAPR`, щоб стейкати токени DAARION для отримання APR винагород.

7.  **Анстейкінг з APR**:
	- Користувачі викликають функцію `unstakeAPR`, щоб вивести свої APR стейкані токени та отримати APR винагороду.

### Діаграма

![DAARDistributor Diagram](https://www.planttext.com/api/plantuml/svg/jLJRQjmm47tNLmnvSi3j1onioH8d40X9SReVCB6cQr5RDjAOXNvzTBEzQsz2GycBaJKpvo8V-SOo6XxQHWYik3EmjsJIylceftMXB1lrEhYr4BqRKPNgKJDS5RjTUGLeeH1YkuK7hLXXe_uIRBT210puzWEA3QYfbFcX7FppuVaf1-gxgduaVU0wXoCs3N5vBOeqDqDQu9gWwZGR9olmlH33dH-7EBzYjSHtCtnsGZKpx7k9J546DA4OmHd_q2Wp8FlZ6O5zCTKoRBj1yumu1CH0d8sxiNK3JhoslydScwxDMdluRabBCZcWb8QipRXMzjgzBZ2ZchWBg6KY0KD7DD86nNjjFz8yw4-hti0jDjNGUARU2LNwC36E7R-IetSQbiRFJIyqZ0uk-QowqUTjWwg5Cj8iNLQ-c6hP5xhpGgQB4Szy5JyvrNtv4seIYICrO6iqDFMSK9vz-dXAyJ9u6PUPvbplVfONC-ts5ydut-IMuSi5mi1m5jKBCb9Crq9E3yZFhNAsq9Z-9JcSYer3xtdxft1wxbYBQJmJ5PEt2kNOurfYHnQmpCVUu1KjIUWqoC4WAxVmLo8qk4uXRfnKz_z-0m00)

    