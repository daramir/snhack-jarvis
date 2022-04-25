# Nile: (compile, test)

1.  ```bash
    source fastecdsa-exports.sh
    ```

1.  ```bash
    pipenv install
    pipenv sync
    ```

1.  ```bash
    pipenv shell
    ```

1.  ```bash
    nile install
    ```
1. Run nile stuff

# Hardhat: (play, hard)

### init
```
yarn install
```
### compile
```
yarn compile:starknet
```
### deploy

#### your accounts
```
npx hardhat starknet-deploy-account --wallet MyWallet --starknet-network testnet
```
#### the contracts
```
yarn deploy:starknet:testnet --starknet-network testnet --gateway-url "https://alpha4.starknet.io"
```
