
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

<details>
<title>UML-код</title>

@startuml

actor User
actor Owner
actor Distributor

participant "DAAR" as D

== Initialize ==

Owner -> D: initialize(DAAR, DAARION, epochLength, walletR)
D -> D: Initializes the contract

== Set Epoch Length ==

Owner -> D: setEpochLength(epochLength)
D -> D: Update epoch length

== Stake DAARION ==

User -> D: stakeDAARION(amount)
D -> D: updateEpoch()
D -> DAARION: transferFrom(msg.sender, address(this), amount)
D -> D: Stake amount and update rewards

== Unstake DAARION ==

User -> D: unstakeDAARION(amount)
D -> D: updateEpoch()
D -> D: Calculate pending rewards
D -> D: Transfer pending rewards
D -> DAARION: transfer(msg.sender, amount)
D -> D: Unstake amount and update records

== Claim Rewards ==

User -> D: claimRewards()
D -> D: updateEpoch()
D -> D: Calculate pending rewards
D -> D: Transfer pending rewards

== Distribute DAAR ==

Owner -> D: distributeDAAR()
D -> D: updateEpoch()
D -> D: Calculate rewards per share
D -> D: Distribute rewards

== Update Epoch ==

D -> D: updateEpoch()

== Stake APR ==

User -> D: stakeAPR(amount)
D -> DAARION: transferFrom(msg.sender, address(this), amount)
D -> D: Record APR stake

== Unstake APR ==

User -> D: unstakeAPR(amount)
D -> D: Calculate APR rewards
D -> DAAR: transferFrom(walletR, msg.sender, reward)
D -> DAARION: transfer(msg.sender, amount)
D -> D: Unstake APR amount

== Calculate APR Reward ==

User -> D: calculateAPRReward(staker)
D -> D: Calculate APR reward based on duration and APR rate

@enduml

</details>

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

    

## APRStaking Контракт

Звичайно, ось простий пояснювальний текст на українській мові, зрозумілий для органічних фермерів:

---

## Контракт APRStaking

Контракт `APRStaking` допомагає фермерам отримувати винагороди за зберігання своїх токенів `DAARION`. Коли ви ставите свої токени `DAARION` у цей контракт, ви отримуєте додаткові токени `DAAR` як винагороду.

### Як це працює?

1. **Ставка токенів (stake)**

    Ви можете поставити (застейкати) певну кількість токенів `DAARION`, які ви маєте. Ці токени будуть зберігатися у контракті `APRStaking`.

    ```solidity
    function stakeAPR(uint256 _amount) external nonReentrant
    ```

2. **Зняття токенів (unstake)**

    Коли ви хочете забрати свої токени, ви можете зняти їх з контракту. Окрім повернення ваших токенів `DAARION`, ви отримаєте додаткові токени `DAAR` як винагороду за те, що зберігали свої токени у контракті.

    ```solidity
    function unstakeAPR(uint256 _amount) external nonReentrant
    ```

3. **Розрахунок винагороди**

    Винагорода обчислюється залежно від того, скільки часу ваші токени були у контракті і яка фіксована річна процентна ставка (APR).

    ```solidity
    function calculateAPRReward(address staker) public view returns (uint256)
    ```

### Що ще важливо знати?

- **walletR** - це спеціальний гаманець, з якого виплачуються винагороди у вигляді токенів `DAAR`.
- **Події** - коли ви ставите або знімаєте токени, контракт надсилає повідомлення про це. Ви можете бачити ці повідомлення як підтвердження, що ваша операція успішна.

### Що вам дає цей контракт?

Контракт `APRStaking` дозволяє вам:

- Отримувати додаткові токени `DAAR` за зберігання ваших токенів `DAARION`.
- Впевненість у тому, що ваші токени безпечно зберігаються і можуть бути зняті у будь-який момент разом з винагородами.

Таким чином, ви можете заробляти більше, просто зберігаючи свої токени на контракті `APRStaking`.

---

### Функціонал та Особливості  

1. **Основні функції**

    - **stakeAPR** - ця функція дозволяє користувачам ставити певну кількість токенів `DAARION`. Токени переводяться з гаманця користувача на контракт `APRStaking`.
        ```solidity
        function stakeAPR(uint256 _amount) external nonReentrant
        ```

    - **unstakeAPR** - ця функція дозволяє користувачам знімати свої токени `DAARION` з контракту. Водночас користувачі отримують винагороду у вигляді токенів `DAAR`, розраховану за фіксованою річною процентною ставкою.
        ```solidity
        function unstakeAPR(uint256 _amount) external nonReentrant
        ```

    - **calculateAPRReward** - ця функція розраховує винагороду для користувача на основі часу, протягом якого токени були на контракті, та фіксованої річної процентної ставки.
        ```solidity
        function calculateAPRReward(address staker) public view returns (uint256)
        ```

2. **Внутрішні функції**

    - **initialize** - ця функція ініціалізує контракт, встановлюючи адреси токенів `DAAR`, `DAARION`, резервного гаманця (walletR) і власника (owner).
        ```solidity
        function initialize(address _DAAR, address _DAARION, address _walletR, address owner) public initializer
        ```

3. **Події**

    - **APRStakeEvent** - ця подія відправляється щоразу, коли користувач ставить токени `DAARION`.
        ```solidity
        event APRStakeEvent(address indexed user, uint256 amount)
        ```

    - **APRUnstakeEvent** - ця подія відправляється щоразу, коли користувач знімає свої токени `DAARION`.
        ```solidity
        event APRUnstakeEvent(address indexed user, uint256 amount)
        ```

    - **APRRewardClaimed** - ця подія відправляється щоразу, коли користувач отримує винагороду у вигляді токенів `DAAR`.
        ```solidity
        event APRRewardClaimed(address indexed user, uint256 reward)
        ```

### Деталі контракту

1. **Поля контракту**

    - **DAAR** - адреса контракту токена `DAAR`.
    - **DAARION** - адреса контракту токена `DAARION`.
    - **apr** - фіксована річна процентна ставка (APR).
    - **walletR** - резервний гаманець для винагород на основі APR.
    - **aprStakes** - мапа, яка відстежує кількість поставлених токенів та час початку ставки для кожного користувача.

2. **Структури даних**

    - **APRStake** - структура, яка зберігає інформацію про ставку користувача, включаючи кількість токенів та час початку ставки.
        ```solidity
        struct APRStake {
            uint256 amount;
            uint256 startTime;
        }
        ```

Цей контракт дозволяє користувачам ефективно ставити свої токени `DAARION` та отримувати винагороди у вигляді токенів `DAAR` на основі фіксованої річної процентної ставки.

![ARPstaking Diagram](https://www.planttext.com/api/plantuml/svg/dLH1ReCm4BppYZqIYNmWKgkaQIFbqbQWF61bRreKOv2zJjJVrmwGGY2XBISOcF7ix2vBosZO5If2mQM1dIKJLHxAHLwXPbYzfndZ8TSVFVXvjKgtRwy3B8g20imVEyG5-4CEv84OYz9fdeN3yYCoTUL_RWEzEM01R53RFPcDAOiuY2STKW8NHSMGEI78sWZyrLVhcab9b4P2U2Pe72N0UK7UPb7D9kYxIWRZN3AgiuPiinZoWjr5Yz7BaJGt9RIsILc23URA6RefaDAH34UaPIHfBBhHq9t-H-nTWVKdYKEJK-RsUzzdqkBh7FLMsnRX-fC9zn0FAKtvsRHIpnOguLIe8gKJ6ZdoUUZ8rUISK2dYD84wVtEcrhqUr5FhmXCgrAAsywVYqexuTONtHKS6hJUdC7ze-tePeLyhtHZPyVXwktSrjFS2yTYkDZWsxXFCEhYrGh-CCXvsAcp0xIrO-bVXJ_OD)

<details><title>UML code</title>

```plantuml

@startuml
actor User
participant APRStaking
participant DAARION
participant DAAR

User -> APRStaking: stakeAPR(amount)
activate APRStaking
APRStaking -> DAARION: transferFrom(User, APRStaking, amount)
alt Success
    APRStaking -> APRStaking: Record Stake (amount, timestamp)
    APRStaking -> APRStaking: Update totalStakedDAARION
    APRStaking -> User: APRStakeEvent(User, amount)
else Failure
    APRStaking -> User: Revert
end
deactivate APRStaking

User -> APRStaking: unstakeAPR(amount)
activate APRStaking
APRStaking -> APRStaking: Check Stake Sufficiency
alt Insufficient Stake
    APRStaking -> User: Revert (Insufficient Stake)
else Sufficient Stake
    APRStaking -> APRStaking: Calculate Reward
    APRStaking -> DAAR: transferFrom(walletR, User, reward)
    alt Insufficient Reward Balance
        APRStaking -> User: Revert (Insufficient Reward)
    else Sufficient Balance
        APRStaking -> APRStaking: Update Stake (amount -= unstake amount)
        APRStaking -> APRStaking: Update totalStakedDAARION
        APRStaking -> DAARION: transfer(User, amount)
        APRStaking -> User: APRUnstakeEvent(User, amount)
        APRStaking -> User: APRRewardClaimed(User, reward)
    end
end
deactivate APRStaking
@enduml

```
</details>