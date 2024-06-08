# DAAR and DAARION Smart Contracts
This README provides a comprehensive overview and guide to the DAAR and DAARION smart contracts, ensuring clarity and understanding for developers, stakeholders, and participants.

## Overview

The DAAR and DAARION smart contracts are designed to create an ecosystem for digital asset distribution and revenue sharing on the Polygon blockchain. These contracts provide mechanisms for automatic token distribution, staking, and rewards.

## Features

### DAAR
- **ERC20 Compliant**: Standard ERC20 token functionalities.
- **Burnable**: Allows the burning of tokens.
- **Pausable**: Can pause and unpause contract functionalities.
- **Transaction Fee**: A 0.5% fee on each transaction, sent to a designated wallet (`walletD`).
- **Upgradeable**: Supports role-based access and upgradeability.
#### How it works:

![DAAR Diagram](diagrams/DAAR-concept.svg)


### DAARION
- **ERC20 Compliant**: Standard ERC20 token functionalities.
- **Burnable**: Allows the burning of tokens.
- **Pausable**: Can pause and unpause contract functionalities.
- **Sales Tax**: A 5% tax on each transaction, which is burned.
- **Upgradeable**: Supports role-based access and upgradeability.

### DAARDistributor
- **Staking**: Allows staking of DAARION tokens.
- **Rewards Distribution**: Distributes DAAR tokens as rewards based on staking.
- **Epoch Management**: Operates on epochs for reward distribution.

### APRStaking
- **Staking**: Allows staking of DAARION tokens.
- **APR Rewards**: Provides rewards based on a fixed Annual Percentage Rate (APR).
- **Upgradeable**: Supports role-based access and upgradeability.

## Smart Contract Details

### DAAR Contract

![DAAR Diagram](https://www.plantuml.com/plantuml/svg/hLHDRnCn4BtlhvZZ1gKAN9626YYHSa18RL7FhdTMjUeTH_OiGVnwx5btwmO7miTAbTtupPldzqQ-3AmyZuE5gytc-eCZzafp4_-SXoy1VTv-Fb3SD_i8Djhi5R4KW0goDirw3JioR9GrtnKRHx1UDr855-ycx5imJmXi3yfQvAibk8HPmlJ_zQ99qA9a9aNGMHr4pOpIyjOh2ZrwE1X-W2rYwXfbbqqvOrgFKRb1uYMemOt4YqPPXXkaBXQO0FXDsx733dhl1kWH6uZVaw2vlE3CH0tQW0KHEVuDMRv-IHKX6s63Lathg-bGwUHdkjmAthoEt-9SNN3np5hMIB8HZeFXsSExQ65gWbynef6wbmxBDSwmUHjnRH0hbb2n_2XV_O3w4Q8Rxg188oZgu5xPj9TqDhKJ26FV6sqmN-kS6C-qJB1dn_cV8_tRMFyeMgb8yPPL4bYgwr1xL06V8v7XBd9mVex1K154HOIF3JsNLvxdwWOdUVbt6QhAYn6G2rG4jOI7kFmqH-E-Kun7xiuWeIrSAJ19YFWooxhBGTRbvDEaOzgUafBdeQuXixni_d6QiTMEP9LHEsKCJjXjX2HNbDPkf9DQJCZStL714jYFkAYBFAh9IYklki1sz6z2UcN3AINPaKvw58vzCiIhzwCdk7MFIA7cr10nBRlw2vJFWQMysboQdBhxVUpTredbx9V48ZmJNo9rus1_0000)

---

### DAARION Contract

![DAARION Diagram](https://www.plantuml.com/plantuml/svg/hLLHQzim47xthxYNWJDIiZxiPIobwTf17jQE9g6FvIfVgAWi1-cyXFtwIRBYkiPA4zP0iC3VVNVVzqdofMKqN9SAhcUp-_dTxOzAiq71cVjN1bQMJ5pURRLRPnk7bq9kKFE-1j3kbrasdS9SIvQev5zaMMcOJhDG2sSNRSKta7iGvLjKYlXy39M7ZR88UejlIGb4d14i8rDekJIexThrs4f-XYNkVDULxJVb2CiDEGcID8y1owhMFCfGCIn85wv6Mg2TK7L11QnDLGBZBWFtwqpMCdHe8rT6obA7IrVyFj_LwlxsSNPzVN-pM7GeFNGMM277vlaPB2goNkG4ph-ut-Y4uU3ibR9VvWrp5LHARXrzS8RwLlI7l39TlFNRopdIz9yEcjlWoXW60XYCNJoJU05KgjgY5WIe2tX2vTSXiTdG6x3rUYs5f2Znc6XFYDT3ZuxumsF-ZwXFZjiN-CXxXJx4K5gGC8IMNWCAUx-JIcNQKAJkn38yYd5j3JSwKFZRezrn2t8PUaFyHalSAPPu4JtBdV9mfWFy-nI-VkhrxDJLcmAPMh_xGD-fDMhVmCqJJGgAVPSBtoHH-uwoX-OAJEkAWFrTESeE2OcWBAKXahKImXWtpVQTp7LuDhiuxJKrS7-elTqeH7kAatCzIXkx5BswCR2fQPISk5SMnnx-hWJaN7_8L6jKzi1OqQiYTEju-KjgdbpLHiEoUY5j4nwM3fPpbRu2MnHmu1bK_EJwv6c6Y8WCORpVM5kQhFJ6FnEpXNTvWh0fZD_XuHngVP2XrdsEIz95NQf_)

---
### DAARDistributor Contract

![DAAR Diagram](https://www.plantuml.com/plantuml/svg/pLL1Rjim4Bpp5NjK0VS30Lp4S1p0G94KTlM0DRMEYLAaG2uTeAylI9EHAiIHt5voiysPqUpCMhptZ8v3g-5XjTezACzE7G9RjxQ67KeMADawg3sv_F7vrP0JeaF7IgeE3O-vW7xyan3B9MoDOeLQ_KPMri1oAP8MVFqsXiCTg0AcAXuk4cJx_BG0wgmyVIVpmgS5sAZmHOpvxqdspoUGUJpmZ4p9tPuODb4QBjeJ_ZpnfZTI3KpDT5Dt3J918e9EpFU8qKA4KwiO1a-CTkbCXY_c6NzHYIWwh_rLun6QaHMsDXY-wZYAtG4xDFv8xj7Pjeh2Yx7i0eeGQeQV6G_x82LvVmnQ003S4ajo2OwaTStDPBQCEaLobLlxFjM4tAGiINlg_J-YqfCIEpgJuqj8AEDc2p9DQgKsVdulmOoQwGFTX-DHIKKcUvqVo1gr33fcqf5fb7a1Hw_e6l-HnA3o0WUsQTv2crwMl165-9aN8FOqMe6jyJCpdzw2jKRLmYu7-U4Eo0ZDoEhI_O_SM-6lpgWq7ZJzLuFpiynyQEZ0Sx9S3qOO1FfafoUO7-aRWH9_ubNTlA7ZMVKFxsTnuv-jPDwH0tz2H_C4ohTUOV96-EkScd8bt9DfGgl_0000)

---
### APRStaking Contract

![APRStaking Diagram](https://www.plantuml.com/plantuml/svg/fLJHYjim47pNL-nZ3jmVAAHSclOWBxtYD1-mbTP5L9Q2jBf0lxwIfRYkGwf00mcEc5dDpWn-3eoUusXWzxK_ClxKziVUMVOeMQIlyt0AvElZwyMcPt5E52tr6IqlQ81XyK-8xHOELhD6etyXQsTXknNJ17ZtOSbx3_gAeysdtQxl8FyUNhzqS45ZYDE9oyGdiQ2jXyoN4SYw0GH6fabAnb4cP1LvfHj-o8Xqii7HHSlhkwga16IFDWpaNxmRDtbKjnZKmPMEXk5RXS8nIaaX3D48I9z_hD6JT5uLDL2rTC1wf7GqdfzQ_DDP8HEmOpJJqgegloLEqIOAZNeEaZw_aML19j0VzI-e3Qdx0tfw8y_569GvQq5MJRwVR6Ww7-tA-sBUCGw3bfeib_HQc-_Ho6YGosMUBkYBvjiW5obM80mfpMlTW5sfVMQlfFG5_X4DMbaqFPP8yS5FySwqLiTgc_uIz5y5Q9QW15Pgy1YZEB8tg4TIG3Dnwj31XiUzQtGgOtElvi7DVZJxkIfD4NYtgF8AdhVUPBFgYwdTorgrxnX8WREWeYzlHhIgb1QPn7FI5aSZVWC0)

## Usage Examples

### DAAR Token

1. **Buying and Selling Products**
   - Use DAAR tokens to buy and sell organic products within the GreenFood cooperative.
2. **Transaction Fee**
   - Every transaction deducts a 0.5% fee sent to walletD.
   - For example, sending 100 DAAR results in 0.5 DAAR to walletD and 99.5 DAAR to the recipient.
3. **Reward Distribution**
   - Funds in walletD are distributed monthly among DAARION LP token holders.
   - DAAR rewards are allocated based on each holder's share in DAARION.
#### Use Case Diagram:

![DAAR Use Case Diagram](https://www.plantuml.com/plantuml/svg/RPB1QiCm38RlVWgHUw19McWlerd3RcCZMzdPIqGnIvqXo-jXzDqN5sV3oYv6lxuFWMNl7MjYVnwKxdWaUBfOf5WVtLGgmewrFGq8MLFNBRoE7sW3WuEUZiRe4-bp1jyAuCyD2S0xx8AKlQ3jCz0EZeSo9IrsQBummcg2rsJGSXB30yx-UWdVz30WDr7OB8N6E2RpxdcaA6sNKltS_YFkKl5NG0YhYLAnIgr7Otb6HOhkFTaPbRUhNvKAQuUy7oyslmlxaerAgTihGUu_ev7cIkIro1kHjoBlH2vMib78HgdsQFlmZNu0)

---

### DAARION Token

1. **Transaction Fee**
   - Each transaction applies a sales tax, where a portion of the tokens is burned.
   - For instance, transferring 100 DAARION results in a 5% tax and burn (5 DAARION burned, 95 DAARION received by the recipient).

---

### DAARDistributor Contract

1. **Staking DAARION**
   - Users stake their DAARION tokens to start earning DAAR rewards.
2. **Unstaking DAARION**
   - Users can unstake their DAARION tokens and receive their staked amount along with any accrued rewards.
3. **Claiming Rewards**
   - Users can claim their accumulated DAAR rewards based on their staked DAARION tokens.

---

### APRStaking Contract

1. **Stake Tokens**
   - Users stake a certain amount of DAARION tokens to start earning rewards.
2. **Claim Rewards**
   - Users can claim their accumulated rewards anytime.
3. **Unstake Tokens**
   - Users can unstake their tokens and receive rewards in DAAR.


---

For more details on the GreenFood cooperative and the DAAR and DAARION token ecosystem, visit [GreenFood.live](https://greenfood.live).
