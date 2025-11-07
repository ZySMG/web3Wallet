# Web3Wallet 核心代码总结

## 📁 一、Web3Wallet 核心文件夹结构

Web3Wallet 采用 **Clean Architecture（整洁架构）**，分为三个主要层次：

### 1.1 目录结构概览

```
Web3Wallet/
├── App/                    # 应用入口和协调器
├── Common/                 # 共享组件和工具类
├── Data/                   # 数据层（网络、存储、缓存）
├── Domain/                 # 业务逻辑层（实体、用例、服务）
└── Presentation/           # 展示层（UI、ViewModel、协调器）
```

### 1.2 核心层次说明

#### **App 层** - 应用启动和导航协调
- `ApplicationCoordinator`: 应用级导航协调器，管理整体流程
- `AppContainer`: 依赖注入容器，管理所有服务实例
- `TrustWallet2App`: App 入口

#### **Common 层** - 通用工具
- `Extensions/`: Swift 扩展（Date、Decimal、String）
- `Utilities/`: 工具类（Logger、EIP55 地址校验、QRCode 生成）
- `UI/`: 可复用 UI 组件（Toast）

#### **Data 层** - 数据获取和存储
- `Network/`: 网络服务（Etherscan API、CoinGecko API）
- `Ethereum/`: 以太坊相关服务（余额、交易、Gas）
- `Storage/`: 存储服务（Keychain、UserDefaults）
- `Price/`: 价格服务（多源价格聚合）
- `Cache/`: 缓存服务

#### **Domain 层** - 业务逻辑
- `Entities/`: 实体模型（Wallet、Balance、Transaction、Currency）
- `UseCases/`: 业务用例（创建钱包、导入钱包、发送交易、查询余额）
- `Services/`: 领域服务（钱包管理、派生服务）
- `Validation/`: 验证服务（地址验证、助记词验证）

#### **Presentation 层** - UI 展示
- `Coordinators/`: 导航协调器（OnboardingCoordinator、WalletCoordinator）
- `Scenes/`: 场景页面（钱包首页、发送、接收、交易历史）
- `Components/`: UI 组件（TokenListView）

---

## 🔐 二、四大核心功能点详细分析

### 2.1 钱包管理（创建/导入钱包）

#### **核心流程**

**创建钱包流程：**
1. 生成助记词 → 2. 验证助记词 → 3. 派生地址 → 4. 保存到 Keychain

**导入钱包流程：**
1. 输入助记词 → 2. 验证助记词 → 3. 派生地址 → 4. 保存到 Keychain

#### **核心代码位置**

**用例层（UseCase）：**
- `GenerateMnemonicUseCase.swift`: 生成助记词和创建钱包
- `ImportWalletUseCase.swift`: 导入钱包

**关键代码片段：**

```swift
// GenerateMnemonicUseCase.swift - 生成助记词
func generateMnemonic() -> Observable<String> {
    return Observable.create { observer in
        // 使用 TrustWalletCore 生成 128 位强度的助记词
        guard let hdWallet = HDWallet(strength: 128, passphrase: "") else {
            observer.onError(WalletError.unknown)
            return Disposables.create()
        }
        let mnemonic = hdWallet.mnemonic
        observer.onNext(mnemonic)
        observer.onCompleted()
        return Disposables.create()
    }
}

// GenerateMnemonicUseCase.swift - 从助记词生成钱包
func generateWallet(from mnemonic: String, network: Network) -> Observable<Wallet> {
    return Observable.create { observer in
        // 1. 验证助记词
        guard self.mnemonicValidator.isValid(mnemonic) else {
            observer.onError(WalletError.invalidMnemonic)
            return Disposables.create()
        }
        
        // 2. 创建 HDWallet
        guard let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
            observer.onError(WalletError.invalidMnemonic)
            return Disposables.create()
        }
        派生以太坊地址（BIP44
        // 3.  标准路径）
        let derivationPath = "m/44'/60'/0'/0/0"
        let privateKey = hdWallet.getKey(coin: CoinType.ethereum, derivationPath: derivationPath)
        
        // 4. 生成地址
        guard let privateKeyObj = PrivateKey(data: privateKey.data) else {
            observer.onError(WalletError.invalidAddress)
            return Disposables.create()
        }
        
        let publicKey = privateKeyObj.getPublicKeySecp256k1(compressed: false)
        let address = AnyAddress(publicKey: publicKey, coin: CoinType.ethereum)
        
        // 5. 保存助记词到 Keychain
        let keychainStorage = KeychainStorageService()
        _ = keychainStorage.store(key: "mnemonic_\(address.description)", value: mnemonic)
        
        // 是的，这是 observable.create 的标准流程：
        // 1. 通过 observer.onNext 推送结果
        observer.onNext(wallet)
        // 2. 调用 observer.onCompleted 表示流程结束
        observer.onCompleted()
        // 3. 返回 Disposables.create() 供资源释放和取消订阅
        return Disposables.create()
    }
}
```

**技术要点：**
- 使用 **TrustWalletCore** 的 `HDWallet` 生成和解析助记词
- 遵循 **BIP44** 标准派生路径：`m/44'/60'/0'/0/0`
- 助记词通过 **Keychain** 安全存储
- 使用 `Observable.create { observer in ... }` 是 RxSwift 创建可观察异步流的标准写法。
- `observer.onNext(value)` 推送数据，`observer.onCompleted()` 表示流结束，`observer.onError(error)` 用于错误处理。
- 所有异步步骤都封装在 create 闭包里，最终通过 subscribe 方法实现响应式处理，便于链式调用和取消任务。
- 适合包裹异步操作（如生成助记词、异步网络请求），让数据流可组合、可管理且便于错误处理。

---

### 2.2 资产管理（余额查询）

#### **核心流程**

1. 查询 ETH 余额 → 2. 查询 USDC/USDT 代币余额 → 3. 查询价格 → 4. 计算 USD 总价值

#### **核心代码位置**

**用例层：**
- `ResolveBalancesUseCase.swift`: 统一余额解析用例

**服务层：**
- `EthereumService.swift`: 以太坊服务（余额查询）
- `EtherscanV2Service.swift`: Etherscan API 封装

**关键代码片段：**

```swift
// ResolveBalancesUseCase.swift - 解析多个币种余额
func resolveBalances(for wallet: Wallet, currencies: [Currency]) -> Observable<[Balance]> {
    // 1. 检查缓存
    let cacheKey = "balances_\(wallet.address)_\(wallet.network.chainId)"
    if let cachedBalances: [Balance] = cacheService.get(key: cacheKey) {
        return Observable.just(cachedBalances)
    }
    
    // 2. 确保 ETH, USDC, USDT 始终在列表中（即使余额为 0）
    var currenciesToFetch = currencies
    let alwaysIncludeSymbols = ["ETH", "USDC", "USDT"]
    // ... 添加逻辑
    
    // 3. 并行查询所有币种余额（使用 combineLatest）
    return Observable.combineLatest(
        currenciesToFetch.map { currency in
            ethereumService.getBalance(address: wallet.address, currency: currency, network: wallet.network)
                .map { amount in
                    Balance(currency: currency, amount: amount)
                }
        }
    )
    .do(onNext: { balances in
        // 4. 缓存结果（有效期 20 秒，非定时刷新）
        // 说明：ttl 为 20 秒，表示本地缓存 20 秒内再次调用会返回缓存，过期后才重新请求。并非每 20 秒主动刷新。
        self.cacheService.set(key: cacheKey, value: balances, ttl: 20)
    })
}

// EthereumService.swift - 获取余额
/// 获取指定地址与币种的余额（单位换算：raw 为最小单位）
/// - ETH: raw 为字符串类型的 Wei（1 ETH = 10^18 Wei）
/// - ERC-20（USDC/USDT 等）: raw 为合约最小单位字符串（如 USDC 6 位小数，raw 表示最小单位的数量）
/// 最终返回用户可读的币种数量（Decimal）
func getBalance(address: String, currency: Currency, network: Network) -> Observable<Decimal> {
    if let contract = currency.contractAddress, !contract.isEmpty {
        // ERC-20 代币余额（raw 为合约最小单位，字符串类型）
        // 注意：etherscan.getTokenBalance 返回的是 Observable<String>，.map 只是用来同步地转换每个 emit 出来的 String。
        // 在 RxSwift 里，map 的 block 里只需要返回处理后的"数据（这里是 Decimal）"，不需要外面包一层 Observable。
        // 也就是说，map 是给流（Observable）里的每个元素做转换，而不是创建新的 Observable。
        // 最终返回的类型依然是 Observable<Decimal>，因为 map 只是把每个 String 数据换成 Decimal，不改变流的结构。
        // 举例：Observable<String> 用 map 转换后就变成 Observable<Decimal>，不用 return Observable.just(result...).
        return etherscan.getTokenBalance(address: address, contractAddress: contract, chainId: network.chainId)
            .map { raw -> Decimal in
                // raw 是最小单位余额字符串，比如 USDC 1 USDC = 10^6
                let smallestUnitValue = Decimal(string: raw) ?? 0
                let decimals = currency.decimals
                let unit = pow(10 as Decimal, decimals)
                // 转换成可读余额
                let result = NSDecimalNumber(decimal: smallestUnitValue)
                    .dividing(by: NSDecimalNumber(decimal: unit)).decimalValue
                // 这里直接 return Decimal 就行，RxSwift 会自动把每次处理结果包进 Observable 的流里
                return result.rounded(scale: decimals)
            }
    } else {
        // ETH 原生余额（raw 为 Wei 字符串，1 ETH = 10^18 Wei）
        return etherscan.getETHBalance(address: address, chainId: network.chainId)
            .map { raw -> Decimal in
                let weiValue = Decimal(string: raw) ?? 0
                let divisor = Decimal(1_000_000_000_000_000_000) // 10^18
                // 转换为 ETH 单位
                let result = NSDecimalNumber(decimal: weiValue)
                    .dividing(by: NSDecimalNumber(decimal: divisor)).decimalValue
                return result.rounded(scale: 6)
            }
    }
}
```

**技术要点：**
- 使用 **Observable.combineLatest** 并行查询多个币种余额
- **缓存机制**：20 秒 TTL，减少 API 调用
- **单位转换**：Wei → ETH，最小单位 → 代币数量
- **错误处理**：网络失败时提供默认余额（0）

---

### 2.3 交易历史

#### **核心流程**

1. 查询交易列表 → 2. 解析交易详情 → 3. 缓存结果 → 4. UI 展示

#### **核心代码位置**

**用例层：**
- `FetchTxHistoryUseCase.swift`: 获取交易历史用例

**服务层：**
- `TxService.swift`: 交易服务
- `EtherscanV2Service.swift`: Etherscan 交易查询 API

**ViewModel：**
- `TransactionHistoryViewModel.swift`: 交易历史 ViewModel
- `TransactionHistoryViewController.swift`: 交易历史 UI

**关键代码片段：**

```swift
// FetchTxHistoryUseCase.swift - 获取交易历史
func fetchTransactionHistory(for wallet: Wallet, limit: Int = 10) -> Observable<[Transaction]> {
    // 1. 检查缓存
    let cacheKey = "tx_history_\(wallet.address)_\(wallet.network.chainId)_\(limit)"
    if let cachedTransactions: [Transaction] = cacheService.get(key: cacheKey) {
        return Observable.just(cachedTransactions)
    }
    
    // 2. 从网络获取交易历史
    return txService.getTransactionHistory(address: wallet.address, network: wallet.network, limit: limit)
        .do(onNext: { transactions in
            // 3. 写入缓存，90 秒有效。该策略与余额 20 秒 TTL 缓存分别独立，优化不同业务实时性。
            self.cacheService.set(key: cacheKey, value: transactions, ttl: 90)
        })
}

// TransactionHistoryViewModel.swift - ViewModel 绑定
private func refreshData() {
    isLoadingSubject.accept(true)
    
    fetchTxHistoryUseCase.fetchTransactionHistory(for: wallet, limit: 50)
        .subscribe(onNext: { [weak self] transactions in
            self?.transactionsSubject.accept(transactions)
            self?.isLoadingSubject.accept(false)
        }, onError: { [weak self] error in
            self?.errorSubject.accept(error)
            self?.isLoadingSubject.accept(false)
        })
        .disposed(by: disposeBag)
}
```

**技术要点：**
- **缓存策略**：90 秒 TTL，平衡实时性和性能
- **下拉刷新**：使用 `UIRefreshControl` 触发数据刷新
- **错误处理**：网络错误时显示友好提示

---

### 2.4 发送交易

#### **核心流程**

1. 验证地址和金额 → 2. 估算 Gas → 3. 获取 Nonce 和 GasPrice → 4. 构建并签名交易 → 5. 广播到区块链

#### **核心代码位置**

**用例层：**
- `SendTransactionUseCase.swift`: 发送交易用例
- `EstimateGasUseCase.swift`: Gas 估算用例

**服务层：**
- `EthereumService.swift`: 以太坊服务（获取 Nonce、GasPrice、广播交易）

**ViewModel：**
- `SendViewModel.swift`: 发送页面 ViewModel
- `SendViewController.swift`: 发送页面 UI

**关键代码片段：**

```swift
// SendTransactionUseCase.swift - 发送交易
func sendTransaction(
    from wallet: Wallet,
    to address: String,
    amount: Decimal,
    currency: Currency,
    gasEstimate: GasEstimate,
    mnemonic: String
) -> Observable<String> {
    return Observable.create { observer in
        // 1. 从助记词派生私钥
        guard let hd = HDWallet(mnemonic: mnemonic, passphrase: "") else {
            observer.onError(WalletError.invalidMnemonic)
            return Disposables.create()
        }
        let privateKey = hd.getKey(coin: .ethereum, derivationPath: "m/44'/60'/0'/0/0")
        
        // 2. 并行获取 Nonce 和 GasPrice
        // - Nonce：每个以太坊账户的交易次数（确保交易唯一且顺序正确），由 getNonce(address, network) 查询（对应 eth_getTransactionCount）
        // - GasPrice：每单位 gas 的费用（影响交易费用和速度），由 getGasPrice(network) 查询（对应 eth_gasPrice）
        // - 使用 Observable.zip 并行发起 RPC 请求，提升效率
        let innerDisposable = Observable.zip(
            self.ethereumService.getNonce(address: wallet.address, network: wallet.network),
            self.ethereumService.getGasPrice(network: wallet.network)
        )
        .flatMap { [weak self] (nonce, gasPriceGwei) -> Observable<String> in
            guard let self = self else { return Observable.error(WalletError.unknown) }
            
            // 3. 构建并签名交易
            guard let rawTx = self.buildTransaction(
                from: wallet.address,
                to: address,
                amount: amount,
                currency: currency,
                nonce: nonce,
                // gasPriceGwei: Gas 单价，单位是 Gwei（1 Gwei = 1e9 wei，最终需转为 wei/raw）
                // gasLimit: 本次交易可用的最大 Gas 数量，是手续费消耗上限，实际花费小于等于此值，多余不会扣费
                // wei 与 raw 无区别，wei 是以太坊最小单位，1 ETH = 1e18 wei
                gasPriceGwei: gasPriceGwei,
                gasLimit: gasEstimate.gasLimit,
                chainId: wallet.network.chainId,
                privateKey: privateKey
            ) else {
                return Observable.error(WalletError.transactionCreationFailed)
            }
            
            // 4. 广播交易
            return self.ethereumService.sendRawTransaction(rawTransaction: rawTx, network: wallet.network)
        }
        .subscribe(onNext: { txHash in
            observer.onNext(txHash)
            observer.onCompleted()
        }, onError: { error in
            observer.onError(error)
        })
        
        return Disposables.create {
            innerDisposable.dispose()
        }
    }
}

// SendTransactionUseCase.swift - 构建交易（支持 ETH 和 ERC-20）
private func buildTransaction(...) -> String? {
    var input = EthereumSigningInput()
    input.privateKey = privateKey.data
    input.chainID = hexDataInt(chainId)
    input.nonce = hexDataInt(nonce)
    input.gasLimit = hexData(gasLimitU64)
    input.gasPrice = hexData(gasPriceWei)
    
    var tx = EthereumTransaction()
    
    if let contract = currency.contractAddress, !contract.isEmpty {
        // === ERC-20 代币转账 ===
        input.toAddress = contract // 发送到代币合约地址
        var erc20 = EthereumTransaction.ERC20Transfer()
        erc20.to = to // 实际接收地址
        erc20.amount = Data(hexString: tokenHex) ?? Data()
        tx.erc20Transfer = erc20
    } else {
        // === 原生 ETH 转账 ===
        input.toAddress = to
        var transfer = EthereumTransaction.Transfer()
        transfer.amount = Data(hexString: ethHex) ?? Data()
        tx.transfer = transfer
    }
    
    input.transaction = tx
    
    // 使用 TrustWalletCore 签名
    let output: EthereumSigningOutput = AnySigner.sign(input: input, coin: .ethereum)
    let raw = "0x" + output.encoded.hexString
    return raw
}
```

**技术要点：**
- **Observable.zip**：并行获取 Nonce 和 GasPrice
- **交易构建**：区分 ETH 原生转账和 ERC-20 代币转账
- **签名**：使用 TrustWalletCore 的 `AnySigner` 签名
- **单位转换**：ETH 转换为 Wei，代币转换为最小单位

---

## ⚡ 三、RxSwift 在业务中的实际用法

### 3.1 RxSwift 核心用法分类

#### **1. Observable 创建和转换**

**🔍 Observable.just vs Observable.create 核心区别**

| 特性 | `Observable.just(value)` | `Observable.create { observer in ... }` |
|------|-------------------------|----------------------------------------|
| **用途** | 创建立即发送单个值的 Observable | 创建自定义的 Observable，完全控制发送时机 |
| **执行时机** | 同步执行，订阅时立即发送值 | 异步执行，可以控制何时发送值 |
| **发送次数** | 只能发送一个值，然后自动完成 | 可以发送多个值，需要手动调用 `onCompleted()` |
| **错误处理** | 不能发送错误 | 可以发送错误（`observer.onError()`） |
| **适用场景** | 缓存返回值、默认值、测试数据 | 网络请求、异步操作、需要手动控制的场景 |
| **Disposable** | 自动管理，无需返回 | 需要返回 `Disposables.create()` 或自定义 Disposable |

**详细对比示例：**

```swift
// ========== Observable.just ==========
// ✅ 适用场景：缓存命中、返回默认值、测试数据
func getCachedBalance() -> Observable<Decimal> {
    if let cached: Decimal = cacheService.get(key: "balance") {
        // 立即返回缓存的值，同步执行
        return Observable.just(cached)
        // 等价于：
        // return Observable.create { observer in
        //     observer.onNext(cached)
        //     observer.onCompleted()
        //     return Disposables.create()
        // }
    }
    return fetchBalanceFromNetwork()
}

// ========== Observable.create ==========
// ✅ 适用场景：网络请求、异步操作、需要手动控制发送时机
func fetchBalanceFromNetwork() -> Observable<Decimal> {
    return Observable.create { observer in
        // 网络请求是异步的，需要等待响应
        AF.request(url)
            .responseJSON { response in
                // 在异步回调中控制何时发送值
                switch response.result {
                case .success(let json):
                    let balance = parseBalance(json)
                    observer.onNext(balance)        // 手动发送值
                    observer.onCompleted()          // 手动完成
                case .failure(let error):
                    observer.onError(error)          // 可以发送错误
                }
            }
        // 返回 Disposable，用于取消请求
        return Disposables.create {
            // 可以在这里取消网络请求
            // request.cancel()
        }
    }
}
```

**关键区别总结：**

1. **Observable.just(value)**：
   - 同步创建并立即发送一个值
   - 自动完成，不能发送错误
   - 适合返回已有的值（缓存、默认值）

2. **Observable.create { observer in ... }**：
   - 异步执行，完全控制发送时机
   - 可以发送多个值、错误，需要手动完成
   - 适合包装异步操作（网络请求、Keychain、文件操作）

**常见错误：**

```swift
// ❌ 错误：在 map 中返回 Observable.just
Observable<String>
    .map { raw -> Observable<Decimal> in
        let result = process(raw)
        return Observable.just(result)  // ❌ 错误！返回类型变成 Observable<Observable<Decimal>>
    }

// ✅ 正确：在 map 中直接返回转换后的值
Observable<String>
    .map { raw -> Decimal in
        let result = process(raw)
        return result  // ✅ 正确！map 自动包装成 Observable<Decimal>
    }

// ✅ 正确：如果需要创建新的 Observable，使用 flatMap
Observable<String>
    .flatMap { raw -> Observable<Decimal> in
        let result = process(raw)
        return Observable.just(result)  // ✅ 正确！flatMap 会"展平"嵌套的 Observable
    }
```

**场景 1：网络请求封装**
```swift
// EthereumService.swift - 将 Alamofire 请求封装为 Observable
func getETHBalance(address: String, chainId: Int) -> Observable<String> {
    return Observable.create { observer in
        AF.request(url, method: .get, parameters: params)
            .responseJSON { response in
                switch response.result {
                case .success(let json):
                    // 解析并发送结果
                    observer.onNext(balance)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
        return Disposables.create()
    }
}
```

**场景 2：异步操作包装**
```swift
// GenerateMnemonicUseCase.swift - 包装同步操作
func generateMnemonic() -> Observable<String> {
    return Observable.create { observer in
        guard let hdWallet = HDWallet(strength: 128, passphrase: "") else {
            observer.onError(WalletError.unknown)
            return Disposables.create()
        }
        observer.onNext(hdWallet.mnemonic)
        observer.onCompleted()
        return Disposables.create()
    }
}
```

#### **2. 操作符使用**

**场景 3：并行请求（combineLatest）**
```swift
// ResolveBalancesUseCase.swift - 并行查询多个币种余额
return Observable.combineLatest(
    currenciesToFetch.map { currency in
        ethereumService.getBalance(address: wallet.address, currency: currency, network: wallet.network)
            .map { amount in Balance(currency: currency, amount: amount) }
    }
)
```

**场景 4：延迟和调度（delay, observe）**
```swift
// WalletHomeViewModel.swift - 添加延迟避免 API 限流
resolveBalancesUseCase.resolveBalances(for: currentWallet, currencies: Currency.supportedCurrencies)
    .delay(.milliseconds(200), scheduler: MainScheduler.instance) // 200ms 延迟
    .subscribe(onNext: { balances in
        self?.balancesSubject.accept(balances)
    })
    .disposed(by: disposeBag)
```

**场景 5：防抖（debounce）**
// 你的理解是正确的，这里的防抖（debounce）主要目的是避免输入频繁变化时（如用户输入或修改收款地址和转账金额的过程中），对 gas 估算接口发起过多、无意义的调用。
// 只有当用户停止输入超过 500ms，才会触发一次 gas 估算请求，减少不必要的计算和 API 请求压力。

// 实现示例：对 toAddress 和 amount 同步监听，输入变化后防抖 500ms 才真正发起估算
Observable.combineLatest(
    input.toAddress.asObservable(),
    input.amount.asObservable()
)
.debounce(.milliseconds(500), scheduler: MainScheduler.instance) // 500ms 防抖，用户输入稳定500ms后再触发
.filter { address, amount in
    // 地址合法且金额非空才触发估算
    address.isValidEthereumAddressFormat && !amount.isEmpty
}
.flatMap { address, amount -> Observable<GasEstimate> in
    // 调用 gas 估算逻辑
}
```

**场景 6：错误处理和默认值（catch, onErrorJustReturn）**
```swift
// SendViewModel.swift - Gas 估算失败时返回默认值
.estimateGas(...)
.catch { _ in
    // 返回默认 Gas 估算
    return Observable.just(GasEstimate(
        gasLimit: Decimal(21000),
        gasPrice: Decimal(20),
        feeInETH: Decimal(21000) * Decimal(20) / Decimal(1_000_000_000)
    ))
}
```

**场景 7：并行请求后组合（zip）**
```swift
// SendTransactionUseCase.swift - 并行获取 Nonce 和 GasPrice
Observable.zip(
    self.ethereumService.getNonce(address: wallet.address, network: wallet.network),
    self.ethereumService.getGasPrice(network: wallet.network)
)
.flatMap { (nonce, gasPriceGwei) -> Observable<String> in
    // 使用 Nonce 和 GasPrice 构建交易
}
```

#### **3. RxCocoa UI 绑定**

**场景 8：Button 点击绑定**
```swift
// WalletHomeViewController.swift - 按钮点击绑定
receiveButton.rx.tap
    .bind(to: viewModel.input.receiveTrigger)
    .disposed(by: disposeBag)

sendButton.rx.tap
    .bind(to: viewModel.input.sendTrigger)
    .disposed(by: disposeBag)
```

**场景 9：TableView 数据绑定**
```swift
// TransactionHistoryViewController.swift - TableView 数据绑定
viewModel.output.transactions
    .drive(tableView.rx.items(cellIdentifier: "TransactionCell", cellType: TransactionCell.self)) { _, transaction, cell in
        cell.configure(with: transaction)
    }
    .disposed(by: disposeBag)
```

**场景 10：Text 绑定和验证**
```swift
// SendViewModel.swift - 地址验证
input.toAddress
    .map { address in
        if address.isEmpty {
            return ""
        } else if address.isValidEthereumAddressFormat {
            return "✓ Valid address"
        } else {
            return "✗ Invalid address format"
        }
    }
    .bind(to: addressValidationSubject)
    .disposed(by: disposeBag)
```

**场景 11：RefreshControl 绑定**
```swift
// WalletHomeViewController.swift - 下拉刷新
refreshControl.rx.controlEvent(.valueChanged)
    .bind(to: viewModel.input.refreshTrigger)
    .disposed(by: disposeBag)

// 绑定加载状态
viewModel.output.isLoading
    .drive(refreshControl.rx.isRefreshing)
    .disposed(by: disposeBag)
```

**场景 12：NotificationCenter 监听**
```swift
// WalletHomeViewController.swift - 监听钱包切换通知
NotificationCenter.default.rx
    .notification(.walletSwitched)
    .compactMap { $0.object as? Wallet }
    .subscribe(onNext: { [weak self] wallet in
        self?.viewModel.switchToWallet(wallet)
    })
    .disposed(by: disposeBag)

// WalletHomeViewModel.swift - 监听应用前台唤醒
NotificationCenter.default.rx
    .notification(UIApplication.willEnterForegroundNotification)
    .map { _ in () }
    .bind(to: input.refreshTrigger)
    .disposed(by: disposeBag)
```

#### **4. BehaviorRelay 状态管理**

**场景 13：ViewModel 状态管理**
```swift
// WalletHomeViewModel.swift - 使用 BehaviorRelay 管理状态
private let totalBalanceSubject = BehaviorRelay<String>(value: "Total Assets: $0.00")
private let balancesSubject = BehaviorRelay<[Balance]>(value: [])
private let transactionsSubject = BehaviorRelay<[Transaction]>(value: [])
private let isLoadingSubject = BehaviorRelay<Bool>(value: false)

// 转换为 Driver 输出（保证在主线程）
self.output = WalletHomeOutput(
    totalBalance: totalBalanceSubject.asDriver(),
    balances: balancesSubject.asDriver(),
    transactions: transactionsSubject.asDriver(),
    isLoading: isLoadingSubject.asDriver()
)
```

**场景 14：组合验证（combineLatest）**
```swift
// SendViewModel.swift - 表单验证
Observable.combineLatest(
    input.toAddress.map { $0.isValidEthereumAddressFormat },
    input.amount.map { !$0.isEmpty && Double($0) != nil },
    currentBalanceSubject.asObservable()
)
.map { isValidAddress, isValidAmount, balance in
    return isValidAddress && isValidAmount && balance > 0
}
.bind(to: isSendEnabledSubject)
.disposed(by: disposeBag)
```

#### **5. 单例状态管理（WalletManagerSingleton）**

**场景 17：全局状态管理**
```swift
// WalletManager.swift - 单例管理钱包状态
class WalletManagerSingleton {
    static let shared = WalletManagerSingleton()
    
    // 使用 BehaviorRelay 管理状态
    let currentWalletSubject = BehaviorRelay<Wallet?>(value: nil)
    let allWalletsSubject = BehaviorRelay<[Wallet]>(value: [])
    
    // 提供 Driver 接口（保证主线程）
    var currentWalletDriver: Driver<Wallet?> {
        return currentWalletSubject.asDriver()
    }
    
    var allWalletsDriver: Driver<[Wallet]> {
        return allWalletsSubject.asDriver()
    }
    
    // 更新当前钱包
    func setCurrentWallet(_ wallet: Wallet) {
        currentWalletSubject.accept(wallet)
        saveCurrentWalletToKeychain(wallet)
        // 发送通知
        NotificationCenter.default.post(name: .walletSwitched, object: wallet)
    }
}

// 在 ViewModel 中监听状态变化
walletManager.allWalletsDriver
    .drive(onNext: { [weak self] wallets in
        self?.updateWalletSections(wallets)
    })
    .disposed(by: disposeBag)
```

**技术要点：**
- **单例模式**：全局唯一的状态管理器
- **BehaviorRelay**：提供当前值和可观察流
- **Driver**：保证主线程执行，不发送错误
- **持久化**：状态变化时同步保存到 Keychain
- **通知机制**：状态变化时发送 Notification

#### **6. Driver vs Observable**

**场景 15：Driver 的使用（UI 绑定）**
```swift
// Driver 特点：
// 1. 不发送错误（onError 会被转换为完成）
// 2. 保证在主线程
// 3. 共享订阅（shareReplay）

// ViewModel Output 使用 Driver
struct WalletHomeOutput {
    let totalBalance: Driver<String>
    let balances: Driver<[Balance]>
    let isLoading: Driver<Bool>
    let error: Driver<Error>
}

// ViewController 绑定使用 drive
viewModel.output.totalBalance
    .drive(balanceLabel.rx.text)
    .disposed(by: disposeBag)
```

#### **6. flatMap 链式调用**

**场景 16：顺序依赖请求**
```swift
// SendTransactionUseCase.swift - 链式调用
Observable.zip(getNonce(), getGasPrice())
    .flatMap { [weak self] (nonce, gasPrice) -> Observable<String> in
        // 使用 Nonce 和 GasPrice 构建交易
        guard let rawTx = self?.buildTransaction(...) else {
            return Observable.error(WalletError.transactionCreationFailed)
        }
        // 广播交易
        return self?.ethereumService.sendRawTransaction(rawTransaction: rawTx, network: network) ?? .empty()
    }
    .subscribe(onNext: { txHash in
        // 处理成功
    }, onError: { error in
        // 处理错误
    })
```

---

### 3.2 RxSwift 使用模式总结

#### **MVVM 架构中的 RxSwift 模式**

```
┌─────────────────────────────────────────────────────────────┐
│                     ViewController                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  UI 控件绑定                                          │   │
│  │  - button.rx.tap → input.trigger                     │   │
│  │  - output.data → label.rx.text (Driver)              │   │
│  │  - output.items → tableView.rx.items                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────────┐
│                     ViewModel                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Input (PublishRelay)                                 │   │
│  │  - refreshTrigger                                     │   │
│  │  - sendTrigger                                        │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  业务逻辑 (Observable 链式调用)                        │   │
│  │  - UseCase.method()                                   │   │
│  │    .delay(...)                                        │   │
│  │    .subscribe(onNext: { ... })                        │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Output (BehaviorRelay → Driver)                      │   │
│  │  - balancesSubject.accept(newValue)                   │   │
│  │  - output.balances = balancesSubject.asDriver()      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────────┐
│                     UseCase                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Observable 封装                                       │   │
│  │  - Observable.create { observer in ... }            │   │
│  │  - Observable.combineLatest([...])                    │   │
│  │  - Observable.zip(...)                                │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

#### **常用操作符场景映射**

| 操作符 | 使用场景 | 代码位置 |
|--------|---------|---------|
| `Observable.create` | 包装异步操作（网络请求、Keychain） | `EthereumService.swift`, `GenerateMnemonicUseCase.swift` |
| `Observable.combineLatest` | 并行查询多个数据源后合并 | `ResolveBalancesUseCase.swift` |
| `Observable.zip` | 并行请求且需要一一对应 | `SendTransactionUseCase.swift` |
// 为什么要用 `flatMap`？  
// `flatMap` 一般用于“上一个异步请求的结果决定下一个请求的参数/行为”，适合链式异步依赖调用。比如在 `SendTransactionUseCase.swift` 里：  
// - 先并行取 nonce 和 gasPrice（用 zip），然后需要 nonce、gasPrice 等参数生成 rawTx，最后用 rawTx 继续发送交易。这时 “生成 rawTx” 和 “广播 rawTx” 是有先后依赖的，不能直接用 map，因为 map 只做同步转换，不能返回一个新的 Observable 并嵌套执行异步流；而 flatMap 能保证前者完成后，继续异步执行下一个请求。  
// - 用 map 只能做数据一次性同步转换，比如 [Int] 转 [String]——它不会发起下一步异步请求。如果你在 flatMap 里写的逻辑只是简单的数据映射，其实就应该用 map。  
// > 结论：  
// > - 若是数据结构/内容的同步转换，用 map（如 Int->String）；  
// > - 若要依据上一个异步请求结果动态发起新异步请求/操作，才用 flatMap（如 nonce/gasPrice 拿到后发送交易）。  
| `flatMap` | 链式异步依赖（如取 nonce、gasPrice 后发交易）适合用 flatMap。 | `SendTransactionUseCase.swift` |
| `map` | 数据转换 | 所有 ViewModel |
| `filter` | 过滤无效输入 | `SendViewModel.swift` |
| `debounce` | 防抖（减少频繁请求） | `SendViewModel.swift` (Gas 估算) |
| `delay` | 延迟执行（避免 API 限流） | `WalletHomeViewModel.swift` |
| `catch` | 错误处理和默认值 | `SendViewModel.swift` |
| `do(onNext:)` | 用于在 Observable 链中执行副作用（如缓存、日志），不影响流内的数据。只有 Observable (或 Single/Maybe/Completable 等 RxSwift “流对象”) 才能用 `do(onNext:)`，普通数组等不行。**示例：**<br/>✅ 正确用法：<br/>`observable.do(onNext: { value in print(value) })`<br/>❌ 错误用法：<br/>`[1,2,3].do(onNext: { ... })  // 数组不能用 do(onNext:)` | `ResolveBalancesUseCase.swift` |

#### **状态管理模式**

```swift
// 1. 使用 BehaviorRelay 管理状态
private let balancesSubject = BehaviorRelay<[Balance]>(value: [])

// 2. 更新状态
balancesSubject.accept(newBalances)

// 3. 转换为 Driver 输出（保证主线程、不发送错误）
output.balances = balancesSubject.asDriver()

// 4. ViewController 绑定
viewModel.output.balances
    .drive(tableView.rx.items) { ... }
    .disposed(by: disposeBag)
```

---

## 🏗️ 四、核心组件详细说明

### 4.1 实体模型（Entities）

#### **Wallet 实体**

```swift
// Wallet.swift - 钱包实体
struct Wallet: Equatable, Codable {
    let id: String                    // 钱包唯一标识
    let name: String                  // 钱包名称
    let address: String               // 以太坊地址
    let network: Network              // 网络类型（主网/测试网）
    let createdAt: Date               // 创建时间
    let isImported: Bool              // 是否导入的钱包
    let fingerprint: String          // 钱包指纹（用于识别）
    
    /// 显示名称（如果 name 为空则使用地址前缀）
    var displayName: String {
        return name.isEmpty ? "Wallet \(id.prefix(8))" : name
    }
    
    /// 格式化地址显示（前6位...后4位）
    var formattedAddress: String {
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(4))
        return "\(prefix)…\(suffix)"
    }
}
```

**设计要点：**
- 遵循 `Codable` 协议，便于 JSON 序列化/反序列化
- 提供便捷的计算属性（`displayName`、`formattedAddress`）
- 使用 `Equatable` 便于比较和去重

#### **Balance 实体**

```swift
// Balance.swift - 余额实体
struct Balance: Equatable {
    let currency: Currency            // 币种（ETH/USDC/USDT）
    let amount: Decimal              // 余额数量
    var usdValue: Decimal?           // USD 价值（可选）
    let lastUpdated: Date            // 最后更新时间
}
```

**设计要点：**
- `usdValue` 为可选，因为价格查询可能失败
- 使用 `Decimal` 类型保证精度（避免浮点数误差）

#### **Transaction 实体**

```swift
// Transaction.swift - 交易实体
struct Transaction: Equatable {
    let hash: String                 // 交易哈希
    let from: String                 // 发送地址
    let to: String                   // 接收地址
    let amount: Decimal              // 交易金额
    let currency: Currency           // 币种
    let status: TransactionStatus    // 状态（成功/失败/待确认）
    let direction: TransactionDirection // 方向（收入/支出）
    let timestamp: Date               // 时间戳
    let network: Network              // 网络
}
```

---

### 4.2 Coordinator 模式详解

#### **Coordinator 的作用**

Coordinator 模式负责**导航流程管理**，将导航逻辑从 ViewController 中分离出来，实现：
- **职责分离**：ViewController 只负责 UI，Coordinator 负责导航
- **可测试性**：导航逻辑可以独立测试
- **可复用性**：相同的 ViewController 可以在不同流程中复用

#### **Coordinator 层级结构**

```
ApplicationCoordinator (根协调器)
    ├── OnboardingCoordinator (引导流程)
    │   └── 创建钱包 / 导入钱包
    └── WalletCoordinator (钱包主流程)
        ├── WalletHomeViewController
        ├── SendViewController
        ├── ReceiveViewController
        └── TransactionHistoryViewController
```

#### **核心代码示例**

```swift
// WalletCoordinator.swift - 钱包协调器
class WalletCoordinator: BaseCoordinator {
    private let disposeBag = DisposeBag()
    private let wallet: Wallet
    private let appContainer: AppContainer
    
    override func start() {
        showWalletHome()
    }
    
    private func showWalletHome() {
        let homeVC = WalletHomeViewController()
        let homeVM = WalletHomeViewModel(
            wallet: wallet,
            resolveBalancesUseCase: appContainer.resolveBalancesUseCase,
            fetchTxHistoryUseCase: appContainer.fetchTxHistoryUseCase,
            priceService: appContainer.priceService
        )
        homeVC.viewModel = homeVM
        homeVC.appContainer = appContainer
        
        // ✅ 使用 RxSwift 绑定 ViewModel 输出到导航
        homeVM.output.showSend
            .drive(onNext: { [weak self] wallet in
                self?.showSend(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        navigationController.setViewControllers([homeVC], animated: false)
    }
    
    private func showSend(wallet: Wallet) {
        let sendVC = SendViewController()
        let sendVM = SendViewModel(...)
        sendVC.viewModel = sendVM
        navigationController.pushViewController(sendVC, animated: true)
    }
}
```

**技术要点：**
- Coordinator 持有 `navigationController`，负责页面跳转
- 使用 **RxSwift Driver** 绑定 ViewModel 输出到导航操作
- 通过 `appContainer` 进行依赖注入

---

### 4.3 网络层详细实现

#### **网络服务架构**

```
NetworkService (基础网络层)
    └── EtherscanV2Service (Etherscan API 封装)
        ├── getETHBalance()
        ├── getTokenBalance()
        └── getTransactionHistory()
```

#### **Etherscan API 封装**

```swift
// EtherscanV2Service.swift - Etherscan V2 API 封装
class EtherscanV2Service {
    private let apiKey: String
    private let baseURL: String
    private let chainId: String
    
    /// 获取 ETH 余额
    func getETHBalance(address: String, chainId: Int) -> Observable<String> {
        return Observable.create { observer in
            let parameters: [String: Any] = [
                "apikey": self.apiKey,
                "chainid": self.chainId,
                "module": "account",
                "action": "balance",
                "address": address,
                "tag": "latest"
            ]
            
            AF.request(self.baseURL, method: .get, parameters: parameters)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success(let json):
                        // 解析响应
                        if let dict = json as? [String: Any],
                           let status = dict["status"] as? String,
                           status == "1",
                           let result = dict["result"] as? String {
                            observer.onNext(result)
                            observer.onCompleted()
                        } else {
                            // API 错误时返回 "0" 而不是 error（容错处理）
                            observer.onNext("0")
                            observer.onCompleted()
                        }
                    case .failure(let error):
                        // 网络错误时返回 "0"（容错处理）
                        observer.onNext("0")
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
}
```

**设计要点：**
- **容错设计**：API 错误或网络错误时返回 `"0"` 而不是 `onError`，保证 UI 不崩溃
- **统一接口**：所有网络请求返回 `Observable<String>`，上层统一处理
- **参数验证**：使用 `validate()` 进行 HTTP 状态码验证

#### **网络错误处理策略**

```swift
// WalletHomeViewModel.swift - 网络错误处理
fetchTxHistoryUseCase.fetchTransactionHistory(for: currentWallet, limit: 10)
    .subscribe(onNext: { [weak self] transactions in
        self?.transactionsSubject.accept(transactions)
    }, onError: { [weak self] error in
        // ✅ 详细的错误分类处理
        if let nsError = error as NSError? {
            if nsError.domain == "NSURLErrorDomain" && nsError.code == -1003 {
                // DNS 解析失败
                self?.errorSubject.accept(WalletError.networkError("Network connection failed."))
            } else if nsError.domain == "NSURLErrorDomain" && nsError.code == -1001 {
                // 请求超时
                self?.errorSubject.accept(WalletError.networkError("Request timeout."))
            } else if nsError.code == 429 {
                // API 限流
                self?.errorSubject.accept(WalletError.networkError("API rate limit exceeded."))
            } else {
                self?.errorSubject.accept(WalletError.networkError("Network error: \(nsError.localizedDescription)"))
            }
        }
    })
    .disposed(by: disposeBag)
```

---

### 4.4 RxSwift 进阶用法补充

#### **场景 18：重试机制（Retry）**

虽然当前项目未使用，但可以在网络请求中添加重试：

```swift
// 示例：网络请求失败时重试 3 次
ethereumService.getBalance(address: address, currency: currency, network: network)
    .retry(3)  // 失败后重试 3 次
    .subscribe(onNext: { balance in
        // 处理成功
    }, onError: { error in
        // 3 次重试后仍失败
    })
    .disposed(by: disposeBag)

// 带延迟的重试（指数退避）
.retry { (error, retryCount) -> Observable<Int> in
    if retryCount < 3 {
        let delay = pow(2.0, Double(retryCount)) // 1s, 2s, 4s
        return Observable<Int>.timer(.seconds(Int(delay)), scheduler: MainScheduler.instance)
    }
    return Observable.error(error)
}
```

#### **场景 19：超时处理（Timeout）**

```swift
// 网络请求超时处理
ethereumService.getBalance(address: address, currency: currency, network: network)
    .timeout(.seconds(10), scheduler: MainScheduler.instance)
    .catch { error in
        // 超时后返回默认值
        return Observable.just(Decimal(0))
    }
    .subscribe(onNext: { balance in
        // 处理结果
    })
    .disposed(by: disposeBag)
```

#### **场景 20：共享订阅（Share）**

```swift
// 避免重复请求（多个订阅者共享同一个 Observable）
let balanceObservable = ethereumService.getBalance(address: address, currency: currency, network: network)
    .share(replay: 1)  // 共享订阅，缓存最后一个值
    // 如果不加 .share(replay: 1)，每次有新的订阅者，Observable 都会重新执行原始逻辑（如每次都重新请求网络）。
    // 例如：如果 balanceObservable 没有 .share(replay: 1)，下面两个订阅者会分别触发两次 getBalance 网络请求，
    // 导致重复请求、浪费资源；加了 .share(replay: 1) 后，两个订阅者会共享同一个结果，只请求一次。
    // 场景举例：
    // let balanceObservable = ethereumService.getBalance(...)
    // balanceObservable.subscribe(...) // 第一次请求
    // balanceObservable.subscribe(...) // 又会再发起一次相同请求（若没加 share）

// 多个订阅者使用同一个 Observable
balanceObservable
    .subscribe(onNext: { balance in
        // 订阅者 1
    })
    .disposed(by: disposeBag)

balanceObservable
    .subscribe(onNext: { balance in
        // 订阅者 2（不会触发新的网络请求）
    })
    .disposed(by: disposeBag)
```

#### **场景 21：条件重试（Retry When）**

```swift
// 只在特定错误时重试
ethereumService.getBalance(address: address, currency: currency, network: network)
    .retryWhen { errorObservable in
        errorObservable
            .enumerated()
            .flatMap { (attempt, error) -> Observable<Int> in
                // 只对网络错误重试，其他错误直接失败
                if attempt < 3 && error is AFError {
                    let delay = Double(attempt + 1) // 1s, 2s, 3s
                    return Observable<Int>.timer(.seconds(Int(delay)), scheduler: MainScheduler.instance)
                }
                return Observable.error(error)
            }
    }
    .subscribe(onNext: { balance in
        // 处理成功
    })
    .disposed(by: disposeBag)
```

---

### 4.5 依赖注入（AppContainer）

#### **AppContainer 设计**

```swift
// AppContainer.swift - 依赖注入容器
class AppContainer {
    // 网络服务
    let networkService: NetworkServiceProtocol
    let etherscanV2Service: EtherscanV2Service
    let ethereumService: EthereumServiceProtocol
    
    // 用例
    let resolveBalancesUseCase: ResolveBalancesUseCaseProtocol
    let fetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol
    let sendTransactionUseCase: SendTransactionUseCaseProtocol
    let estimateGasUseCase: EstimateGasUseCaseProtocol
    
    // 其他服务
    let priceService: PriceServiceProtocol
    let cacheService: CacheServiceProtocol
    
    init() {
        // 初始化顺序：基础服务 → 用例 → 业务服务
        self.networkService = NetworkService()
        self.etherscanV2Service = EtherscanV2Service(...)
        self.ethereumService = EthereumService(etherscan: etherscanV2Service)
        
        self.cacheService = CacheService()
        self.resolveBalancesUseCase = ResolveBalancesUseCase(
            ethereumService: ethereumService,
            cacheService: cacheService
        )
        
        // ... 其他初始化
    }
}
```

**设计要点：**
- **单例模式**：全局唯一的依赖容器
- **初始化顺序**：按依赖关系初始化
- **协议抽象**：使用协议而非具体类型，便于测试和替换

---

## 🎯 五、关键设计模式和技术选型

### 5.1 架构模式
- **Clean Architecture**: 清晰的层次分离
- **MVVM + Coordinator**: UI 与业务逻辑分离，导航管理
- **依赖注入**: AppContainer 统一管理依赖

### 5.2 安全设计
- **Keychain 存储**: 敏感数据（助记词、私钥）存储在 Keychain
- **BIP44 标准**: 遵循标准的派生路径
- **地址验证**: EIP-55 格式验证

### 5.3 性能优化
- **缓存机制**: 余额 20 秒缓存，交易历史 90 秒缓存
- **延迟请求**: 使用 delay 避免 API 限流
- **并行请求**: combineLatest/zip 提高效率

### 5.4 错误处理
- **统一错误类型**: WalletError 枚举
- **错误转换**: catch 操作符提供默认值
- **用户友好提示**: 网络错误显示具体原因

---

## 💡 六、最佳实践和开发技巧

### 6.1 RxSwift 最佳实践

#### **1. 内存管理**
```swift
// ✅ 正确：使用 weak self 避免循环引用
resolveBalancesUseCase.resolveBalances(...)
    .subscribe(onNext: { [weak self] balances in
        guard let self = self else { return }
        self.balancesSubject.accept(balances)
    })
    .disposed(by: disposeBag)

// ❌ 错误：没有使用 weak self
.subscribe(onNext: { balances in
    self.balancesSubject.accept(balances) // 可能导致内存泄漏
})
```

#### **2. 线程调度**

**关键问题总结：**
1. **网络请求默认在后台线程**：Alamofire 和 RxSwift 的网络请求默认在后台线程执行
2. **UI 更新必须在主线程**：所有 UI 操作（设置 label.text、更新 tableView 等）必须在主线程
3. **线程切换方式**：使用 `observe(on: MainScheduler.instance)` 或 `Driver` 切换到主线程
4. **Driver 的优势**：自动保证主线程执行，不会发送错误，适合 UI 绑定

```swift
// ✅ 正确：网络请求在后台线程，UI 更新在主线程
// 问题：网络请求默认在后台线程，直接更新 UI 会崩溃
// 解决：使用 observe(on:) 切换到主线程后再更新 UI
ethereumService.getBalance(...)
    .observe(on: MainScheduler.instance)  // 切换到主线程
    .subscribe(onNext: { balance in
        // UI 更新（现在在主线程，安全）
    })

// ✅ 正确：使用 Driver（自动保证主线程）
// 优势：Driver 自动保证在主线程执行，不需要手动切换
// 注意：Driver 不会发送 onError，错误会被转换为完成
output.balances = balancesSubject.asDriver()
viewModel.output.balances
    .drive(label.rx.text)  // 自动在主线程，线程安全
```

**线程调度最佳实践：**
- **网络请求**：默认在后台线程，无需手动指定
- **UI 绑定**：优先使用 `Driver`，自动保证主线程
- **数据转换**：在 `map`、`flatMap` 等操作符中可以指定线程
- **错误处理**：`Driver` 不发送错误，适合 UI 场景；`Observable` 可以发送错误，适合业务逻辑

#### **3. 错误处理策略**
```swift
// ✅ 正确：提供默认值而不是崩溃
fetchTxHistoryUseCase.fetchTransactionHistory(...)
    .catch { error in
        // 返回空数组而不是传递错误
        return Observable.just([])
    }
    .subscribe(onNext: { transactions in
        // 处理结果
    })

// ✅ 正确：错误分类处理
.catch { error in
    if error is NetworkError {
        return Observable.just([])
    } else {
        return Observable.error(error)  // 其他错误继续传递
    }
}
```

#### **4. 避免重复订阅**
```swift
// ✅ 正确：使用 share 避免重复请求
let balanceObservable = ethereumService.getBalance(...)
    .share(replay: 1)

balanceObservable.subscribe(...)  // 订阅者 1
balanceObservable.subscribe(...)  // 订阅者 2（共享同一个请求）
```

### 6.2 MVVM 最佳实践

#### **1. ViewModel 输入输出模式**
```swift
// ✅ 推荐：明确的 Input/Output 结构
struct WalletHomeInput {
    let refreshTrigger = PublishRelay<Void>()
    let sendTrigger = PublishRelay<Void>()
}

struct WalletHomeOutput {
    let balances: Driver<[Balance]>
    let isLoading: Driver<Bool>
    let error: Driver<Error>
}

class WalletHomeViewModel {
    let input = WalletHomeInput()
    let output: WalletHomeOutput
}
```

#### **2. 状态管理**
```swift
// ✅ BehaviorRelay vs. PublishRelay/share(replay: 1) 使用场景区别：
// - BehaviorRelay：用于“状态管理”，总是持有一个最新的状态值，新订阅者立即拿到当前值。常用于余额、数据列表等需要随时获取状态的场景。
// - PublishRelay：用于“事件流”，只传递事件本身，不持有和回放历史值（新订阅者不会收到过往事件）。适合按钮点击等一次性触发事件。
// - share(replay: 1)：常用于网络请求、异步操作等“单次资源获取结果复用”场景。通过 share(replay: 1)，多个订阅者共享同一份网络结果，避免多次发送请求；新订阅者立即收到最新一次结果（如果有结果的话）。
//   例：可以将网络请求的 Observable 用 .share(replay: 1) 转成“热点流”，后续多个页面、组件都能订阅且不会重复触发请求。
// 总结：
// - 管状态（如数据缓存/余额/账户信息）：用 BehaviorRelay
// - 管事件（如点击、刷新触发，无需回放）：用 PublishRelay
// - 需要复用一次性网络/异步结果、避免重复请求：用 share(replay: 1)
// 例如，资产余额 balancesSubject 应用 BehaviorRelay 管理最新余额状态：
private let balancesSubject = BehaviorRelay<[Balance]>(value: [])

// 更新状态
balancesSubject.accept(newBalances)

// 输出转换为 Driver
output.balances = balancesSubject.asDriver()
```

### 6.3 网络层最佳实践

#### **1. 容错设计**
```swift
// ✅ 推荐：网络错误时返回默认值而不是 error
AF.request(url)
    .responseJSON { response in
        switch response.result {
        case .success(let json):
            // 解析成功
            observer.onNext(result)
        case .failure(_):
            // 网络错误时返回默认值（如 "0"）
            observer.onNext("0")
        }
        observer.onCompleted()
    }
```

#### **2. 参数验证**
```swift
// ✅ 推荐：在发送请求前验证参数
func getBalance(address: String, currency: Currency, network: Network) -> Observable<Decimal> {
    // 验证地址格式
    guard address.isValidEthereumAddressFormat else {
        return Observable.error(WalletError.invalidAddress)
    }
    
    // 继续网络请求
    return etherscan.getETHBalance(...)
}
```

### 6.4 代码组织最佳实践

#### **1. 文件组织**
```
Web3Wallet/
├── Domain/
│   ├── Entities/          # 实体模型（一个文件一个实体）
│   ├── UseCases/          # 用例（一个文件一个用例）
│   └── Services/          # 领域服务
├── Data/
│   └── Ethereum/          # 按功能模块组织
└── Presentation/
    └── Scenes/            # 按场景组织
```

#### **2. 命名规范**
```swift
// ✅ 推荐：清晰的命名
class WalletHomeViewModel { }
class ResolveBalancesUseCase { }
protocol EthereumServiceProtocol { }

// ✅ 推荐：协议命名以 Protocol 结尾
protocol NetworkServiceProtocol { }

// ✅ 推荐：UseCase 命名以 UseCase 结尾
class SendTransactionUseCase { }
```

### 6.5 测试建议

#### **1. ViewModel 测试**
```swift
// 示例：ViewModel 测试
func testRefreshData() {
    let viewModel = WalletHomeViewModel(...)
    
    // 触发刷新
    viewModel.input.refreshTrigger.accept(())
    
    // 验证输出
    XCTAssertEqual(viewModel.output.isLoading.value, true)
    // ... 更多断言
}
```

#### **2. UseCase 测试**
```swift
// 示例：UseCase 测试（使用 Mock）
func testResolveBalances() {
    let mockEthereumService = MockEthereumService()
    let useCase = ResolveBalancesUseCase(
        ethereumService: mockEthereumService,
        cacheService: CacheService()
    )
    
    // 执行用例
    let result = try? useCase.resolveBalances(...).toBlocking().first()
    
    // 验证结果
    XCTAssertNotNil(result)
}
```

---

## 🔧 七、缓存服务（CacheService）详细解析

### 7.1 缓存方法调用示例

在项目中，这两个缓存方法的使用场景如下：

```swift
// 1. 缓存交易历史（90 秒 TTL）
self.cacheService.set(key: cacheKey, value: transactions, ttl: 90)

// 2. 缓存余额数据（20 秒 TTL）
self.cacheService.set(key: cacheKey, value: balances, ttl: 20)
```

### 7.2 CacheService 完整实现解析

#### **核心数据结构**

```swift
// CacheItem - 缓存项包装器
struct CacheItem<T: Codable> {
    let value: T              // 缓存的实际值（泛型，支持任何 Codable 类型）
    let timestamp: Date       // 缓存时间戳（记录何时存储）
    let ttl: TimeInterval     // 生存时间（Time To Live，单位：秒）
    
    /// 检查是否过期
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > ttl
        // 计算：当前时间 - 缓存时间 > TTL → 已过期
    }
}
```

**设计要点：**
- 使用泛型 `<T: Codable>` 支持任意可序列化类型
- `timestamp` 记录缓存创建时间，用于计算过期时间
- `ttl` 以秒为单位，例如 `90` 表示 90 秒，`20` 表示 20 秒

#### **CacheService 类结构**

```swift
class CacheService: CacheServiceProtocol {
    // 内存缓存字典：key → CacheItem
    private var cache: [String: Any] = [:]
    
    // 并发队列：保证线程安全
    private let queue = DispatchQueue(label: "cache.queue", attributes: .concurrent)
    // 使用 .concurrent 允许并发读取，但写入需要 barrier
}
```

**线程安全设计：**
- 使用 `DispatchQueue` 保证线程安全
- `.concurrent` 允许并发读取（提高性能）
- `.barrier` 标志确保写入时独占访问

---

### 7.3 `set` 方法详细解析

#### **方法签名**

```swift
func set<T: Codable>(key: String, value: T, ttl: TimeInterval)
```

#### **完整实现**

```swift
func set<T: Codable>(key: String, value: T, ttl: TimeInterval) {
    // 1. 使用 barrier 异步写入（保证线程安全）
    queue.async(flags: .barrier) {
        // 2. 创建缓存项，包含：
        //    - value: 要缓存的数据
        //    - timestamp: 当前时间（Date()）
        //    - ttl: 过期时间（传入的参数）
        let cacheItem = CacheItem(value: value, timestamp: Date(), ttl: ttl)
        
        // 3. 存储到内存字典中
        self.cache[key] = cacheItem
    }
}
```

#### **执行流程示例**

```swift
// 示例 1：缓存交易历史
let cacheKey = "tx_history_0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb_11155111_10"
let transactions: [Transaction] = [...] // 交易数据

cacheService.set(key: cacheKey, value: transactions, ttl: 90)

// 执行过程：
// 1. 创建 CacheItem<[Transaction]>
//    - value: transactions
//    - timestamp: Date() (例如: 2025-01-15 10:00:00)
//    - ttl: 90 (秒)
// 2. 存储到 cache 字典
//    cache["tx_history_..."] = CacheItem(...)
```

```swift
// 示例 2：缓存余额数据
let cacheKey = "balances_0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb_11155111"
let balances: [Balance] = [...] // 余额数据

cacheService.set(key: cacheKey, value: balances, ttl: 20)

// 执行过程：
// 1. 创建 CacheItem<[Balance]>
//    - value: balances
//    - timestamp: Date() (例如: 2025-01-15 10:00:00)
//    - ttl: 20 (秒)
// 2. 存储到 cache 字典
//    cache["balances_..."] = CacheItem(...)
```

#### **关键设计点**

1. **异步写入（async）**：不阻塞调用线程
2. **Barrier 标志**：确保写入时独占访问，其他读写操作等待
3. **自动过期时间**：存储时记录 `timestamp`，读取时检查是否过期

---

### 7.4 `get` 方法详细解析

#### **方法签名**

```swift
func get<T: Codable>(key: String) -> T?
```

#### **完整实现**

```swift
func get<T: Codable>(key: String) -> T? {
    // 1. 同步读取（使用 sync 确保立即返回结果）
    return queue.sync {
        // 2. 尝试从缓存字典中获取 CacheItem
        guard let cacheItem = cache[key] as? CacheItem<T> else {
            // 3. 如果没有找到，返回 nil
            return nil
        }
        
        // 4. 检查是否过期
        if cacheItem.isExpired {
            // 5. 如果过期，删除缓存项并返回 nil
            cache.removeValue(forKey: key)
            return nil
        }
        
        // 6. 如果未过期，返回缓存的值
        return cacheItem.value
    }
}
```

#### **执行流程示例**

```swift
// 示例 1：获取交易历史（90 秒缓存）
let cacheKey = "tx_history_0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb_11155111_10"

// 场景 A：缓存命中且未过期
// 假设：10:00:00 存储，当前时间 10:00:30，TTL = 90 秒
if let cachedTransactions: [Transaction] = cacheService.get(key: cacheKey) {
    // ✅ 命中缓存，直接返回（距离过期还有 60 秒）
    return Observable.just(cachedTransactions)
}

// 场景 B：缓存过期
// 假设：10:00:00 存储，当前时间 10:01:35，TTL = 90 秒
// Date().timeIntervalSince(timestamp) = 95 秒 > 90 秒 → 已过期
if let cachedTransactions: [Transaction] = cacheService.get(key: cacheKey) {
    // ❌ 不会执行，返回 nil
}
// 自动删除过期缓存，返回 nil，需要重新从网络获取

// 场景 C：缓存不存在
// 缓存字典中没有这个 key
if let cachedTransactions: [Transaction] = cacheService.get(key: cacheKey) {
    // ❌ 不会执行，返回 nil
}
// 返回 nil，需要从网络获取
```

```swift
// 示例 2：获取余额数据（20 秒缓存）
let cacheKey = "balances_0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb_11155111"

// 场景 A：缓存命中且未过期（10 秒内）
if let cachedBalances: [Balance] = cacheService.get(key: cacheKey) {
    // ✅ 命中缓存，直接返回
    return Observable.just(cachedBalances)
}

// 场景 B：缓存过期（超过 20 秒）
// 自动删除过期缓存，返回 nil
```

#### **过期检查逻辑详解**

```swift
// CacheItem 中的过期检查
var isExpired: Bool {
    return Date().timeIntervalSince(timestamp) > ttl
}

// 示例计算：
// 存储时间：10:00:00
// 当前时间：10:01:35
// TTL：90 秒
// 
// Date().timeIntervalSince(timestamp) = 95 秒
// 95 > 90 → true（已过期）
```

---

### 7.5 完整使用流程示例

#### **交易历史缓存流程**

```swift
// FetchTxHistoryUseCase.swift
func fetchTransactionHistory(for wallet: Wallet, limit: Int = 10) -> Observable<[Transaction]> {
    // 1. 生成缓存 Key
    let cacheKey = "tx_history_\(wallet.address)_\(wallet.network.chainId)_\(limit)"
    
    // 2. 尝试从缓存获取
    if let cachedTransactions: [Transaction] = cacheService.get(key: cacheKey) {
        // ✅ 缓存命中，直接返回（不发起网络请求）
        return Observable.just(cachedTransactions)
    }
    
    // 3. 缓存未命中，从网络获取
    return txService.getTransactionHistory(address: wallet.address, network: wallet.network, limit: limit)
        .do(onNext: { transactions in
            // 4. 网络请求成功后，缓存结果（90 秒 TTL）
            self.cacheService.set(key: cacheKey, value: transactions, ttl: 90)
        })
}
```

**执行时序图：**
```
时间轴：
10:00:00 - 第一次请求 → 缓存未命中 → 网络请求 → 存储缓存（TTL=90）
10:00:30 - 第二次请求 → 缓存命中 ✅ → 直接返回（不发起网络请求）
10:01:00 - 第三次请求 → 缓存命中 ✅ → 直接返回
10:01:35 - 第四次请求 → 缓存过期 ❌ → 网络请求 → 更新缓存
```

#### **余额数据缓存流程**

```swift
// ResolveBalancesUseCase.swift
func resolveBalances(for wallet: Wallet, currencies: [Currency]) -> Observable<[Balance]> {
    // 1. 生成缓存 Key
    let cacheKey = "balances_\(wallet.address)_\(wallet.network.chainId)"
    
    // 2. 尝试从缓存获取
    if let cachedBalances: [Balance] = cacheService.get(key: cacheKey) {
        // ✅ 缓存命中，直接返回
        return Observable.just(cachedBalances)
    }
    
    // 3. 缓存未命中，从网络并行获取多个币种余额
    return Observable.combineLatest(
        currenciesToFetch.map { currency in
            ethereumService.getBalance(...)
        }
    )
    .do(onNext: { balances in
        // 4. 网络请求成功后，缓存结果（20 秒 TTL，更短的过期时间）
        self.cacheService.set(key: cacheKey, value: balances, ttl: 20)
    })
}
```

**为什么余额缓存时间更短（20 秒 vs 90 秒）？**
- **余额数据**：变化频繁，用户可能频繁转账，需要更及时的数据
- **交易历史**：相对稳定，新增交易不会频繁，可以缓存更长时间

---

### 7.6 线程安全机制详解

#### **并发队列设计**

```swift
private let queue = DispatchQueue(label: "cache.queue", attributes: .concurrent)
```

**`.concurrent` 的作用：**
- 允许多个读取操作并发执行（提高性能）
- 但写入操作需要 `barrier` 标志，确保独占访问

#### **读取操作（并发）**

```swift
func get<T: Codable>(key: String) -> T? {
    return queue.sync {  // 同步执行，但可以并发（多个 get 可以同时执行）
        // 读取操作
    }
}
```

**多个读取操作可以并发：**
```
Thread 1: get("key1") ──┐
Thread 2: get("key2") ──┼─→ 并发执行 ✅
Thread 3: get("key3") ──┘
```

#### **写入操作（独占）**

```swift
func set<T: Codable>(key: String, value: T, ttl: TimeInterval) {
    queue.async(flags: .barrier) {  // barrier 标志：独占访问
        // 写入操作
    }
}
```

**Barrier 的作用：**
- 执行 `set` 时，所有其他操作（读取和写入）都会等待
- 确保写入操作的原子性和一致性

**执行顺序：**
```
时间轴：
10:00:00 - Thread 1: get("key1") ──┐
10:00:01 - Thread 2: get("key2") ──┼─→ 并发执行 ✅
10:00:02 - Thread 3: set("key3", ...) ──┤
10:00:03 - Thread 4: get("key4") ──┘
         ↓
         Thread 3 的 set 操作使用 barrier
         Thread 1, 2, 4 等待 set 完成
         ↓
10:00:04 - set 完成，Thread 1, 2, 4 继续执行
```

---

### 7.7 缓存策略总结

| 数据类型 | TTL | 原因 |
|---------|-----|------|
| **余额数据** | 20 秒 | 数据变化频繁，需要及时更新 |
| **交易历史** | 90 秒 | 数据相对稳定，可以减少 API 调用 |
| **价格数据** | 60 秒（建议） | 价格波动中等频率 |

**缓存 Key 设计：**
```swift
// 交易历史 Key
"tx_history_{address}_{chainId}_{limit}"
// 示例：tx_history_0x742d..._11155111_10

// 余额数据 Key
"balances_{address}_{chainId}"
// 示例：balances_0x742d..._11155111
```

**设计原则：**
1. **唯一性**：Key 必须包含所有影响数据的参数（地址、网络、限制等）
2. **可读性**：Key 包含前缀，便于识别和调试
3. **TTL 选择**：根据数据更新频率选择合适的过期时间

---

## 🎭 八、Coordinator 模式详细解析

### 8.1 Coordinator 模式概述

#### **什么是 Coordinator 模式？**

**Coordinator 模式**（协调器模式）是一种**行为型设计模式**，最初由 Soroush Khanlou 在 2015 年提出，专门用于解决 iOS 开发中导航逻辑混乱的问题。

它属于**命令模式（Command Pattern）**和**中介者模式（Mediator Pattern）**的结合体：
- **命令模式**：将导航操作封装成对象，便于管理和撤销
- **中介者模式**：Coordinator 作为中介者，协调 ViewController 之间的导航

#### **Coordinator 的核心作用**

**1. 导航逻辑集中管理**
```swift
// ❌ 传统方式：ViewController 中直接导航
class WalletHomeViewController: UIViewController {
    @IBAction func sendButtonTapped() {
        let sendVC = SendViewController()
        navigationController?.pushViewController(sendVC, animated: true)
        // 问题：导航逻辑分散在各个 ViewController 中
    }
}

// ✅ Coordinator 方式：导航逻辑集中在 Coordinator
class WalletCoordinator: BaseCoordinator {
    func showSend(wallet: Wallet) {
        let sendVC = SendViewController()
        navigationController.pushViewController(sendVC, animated: true)
        // 优势：所有导航逻辑在一个地方管理
    }
}
```

**2. 职责分离（Separation of Concerns）**
- **ViewController**：只负责 UI 展示和用户交互
- **ViewModel**：负责业务逻辑和数据处理
- **Coordinator**：负责导航流程和页面跳转

**3. 解耦 ViewController**
```swift
// ❌ 传统方式：ViewController 之间相互依赖
class WalletHomeViewController: UIViewController {
    func showSend() {
        let sendVC = SendViewController()
        sendVC.wallet = self.wallet  // 直接传递数据，产生耦合
        navigationController?.pushViewController(sendVC, animated: true)
    }
}

// ✅ Coordinator 方式：ViewController 之间无依赖
class WalletCoordinator: BaseCoordinator {
    func showSend(wallet: Wallet) {
        let sendVC = SendViewController()
        sendVC.wallet = wallet  // Coordinator 负责数据传递
        navigationController.pushViewController(sendVC, animated: true)
    }
}
```

**4. 可测试性增强**
```swift
// 可以独立测试导航逻辑
func testShowSend() {
    let coordinator = WalletCoordinator(...)
    coordinator.showSend(wallet: testWallet)
    
    // 验证：检查 navigationController 的 viewControllers
    XCTAssertEqual(coordinator.navigationController.viewControllers.count, 2)
}
```

**5. 可复用性提升**
```swift
// 同一个 ViewController 可以在不同流程中复用
class WalletHomeViewController: UIViewController {
    // 不需要知道是被哪个 Coordinator 调用的
}

// 在引导流程中使用
class OnboardingCoordinator: BaseCoordinator {
    func showWalletHome() {
        let homeVC = WalletHomeViewController()  // 复用
        navigationController.pushViewController(homeVC, animated: true)
    }
}

// 在钱包流程中使用
class WalletCoordinator: BaseCoordinator {
    func showWalletHome() {
        let homeVC = WalletHomeViewController()  // 复用
        navigationController.pushViewController(homeVC, animated: true)
    }
}
```

#### **设计模式分类**

Coordinator 模式是**多种设计模式的组合**：

**1. 命令模式（Command Pattern）**
- 将导航操作封装成方法（如 `showSend()`, `showReceive()`）
- 可以延迟执行、撤销、记录操作历史

**2. 中介者模式（Mediator Pattern）**
- Coordinator 作为中介者，协调 ViewController 之间的导航
- ViewController 之间不直接通信，通过 Coordinator 中介

**3. 责任链模式（Chain of Responsibility Pattern）**
- 子 Coordinator 可以处理不了的任务，交给父 Coordinator 处理
- 形成协调器树结构

**4. 工厂模式（Factory Pattern）**
- Coordinator 负责创建和配置 ViewController
- 通过 AppContainer 注入依赖（依赖注入）

#### **与传统 MVC 的对比**

| 特性 | 传统 MVC | Coordinator 模式 |
|------|---------|-----------------|
| **导航逻辑位置** | ViewController 中 | Coordinator 中 |
| **ViewController 职责** | UI + 导航 | 只负责 UI |
| **代码复用** | 困难（导航逻辑耦合） | 容易（导航逻辑分离） |
| **测试难度** | 困难（需要实际 UI） | 容易（可测试导航逻辑） |
| **代码组织** | 分散在各个 ViewController | 集中在 Coordinator |

#### **Coordinator 模式解决的问题**

**问题 1：导航逻辑分散**
```swift
// ❌ 问题：每个 ViewController 都有自己的导航逻辑
class WalletHomeViewController {
    func showSend() { ... }
}

class SendViewController {
    func showTransactionDetail() { ... }
}

class TransactionDetailViewController {
    func showExplorer() { ... }
}
// 导航逻辑分散，难以维护
```

**解决方案：**
```swift
// ✅ 解决：所有导航逻辑集中在 Coordinator
class WalletCoordinator {
    func showSend() { ... }
    func showTransactionDetail() { ... }
    func showExplorer() { ... }
}
// 导航逻辑集中，易于维护
```

**问题 2：ViewController 相互依赖**
```swift
// ❌ 问题：ViewController 需要知道下一个页面
class WalletHomeViewController {
    func showSend() {
        let sendVC = SendViewController()
        sendVC.wallet = self.wallet  // 依赖关系
        navigationController?.pushViewController(sendVC, animated: true)
    }
}
```

**解决方案：**
```swift
// ✅ 解决：ViewController 不需要知道下一个页面
class WalletHomeViewController {
    var coordinator: WalletCoordinator?
    
    func sendButtonTapped() {
        coordinator?.showSend()  // 委托给 Coordinator
    }
}
```

**问题 3：难以测试导航流程**
```swift
// ❌ 问题：需要实际 UI 才能测试导航
func testNavigation() {
    let vc = WalletHomeViewController()
    vc.sendButtonTapped()
    // 需要实际 UI 环境才能验证导航
}
```

**解决方案：**
```swift
// ✅ 解决：可以独立测试导航逻辑
func testShowSend() {
    let coordinator = WalletCoordinator(...)
    coordinator.showSend(wallet: testWallet)
    
    // 可以直接验证导航栈
    XCTAssertEqual(coordinator.navigationController.viewControllers.count, 2)
}
```

#### **在项目中的具体应用**

**场景 1：应用启动流程**
```
App 启动
  ↓
ApplicationCoordinator.start()
  ↓
显示 EntrySelectionViewController
  ↓
用户选择"原生钱包"
  ↓
ApplicationCoordinator 判断是否有钱包
  ├─ 有 → 创建 WalletCoordinator → 显示钱包首页
  └─ 无 → 创建 OnboardingCoordinator → 显示引导页
```

**场景 2：钱包创建流程**
```
WelcomeViewController
  ↓ (用户点击"创建钱包")
OnboardingCoordinator.showCreateWallet()
  ↓
CreateWalletViewController
  ↓ (生成助记词)
OnboardingCoordinator.showMnemonic()
  ↓
MnemonicViewController
  ↓ (用户确认)
OnboardingCoordinator 发送通知
  ↓
ApplicationCoordinator 接收通知
  ↓
清理 OnboardingCoordinator
  ↓
创建 WalletCoordinator
  ↓
显示钱包首页
```

**场景 3：发送交易流程**
```
WalletHomeViewController
  ↓ (用户点击"发送")
WalletCoordinator.showSend()
  ↓
显示币种选择 Alert
  ↓ (用户选择 ETH)
WalletCoordinator.showSendViewController(currency: .eth)
  ↓
SendViewController
```

#### **Coordinator 模式的优势总结**

1. ✅ **导航逻辑集中管理**：所有导航代码在一个地方，易于维护
2. ✅ **职责分离清晰**：ViewController 只负责 UI，不关心导航
3. ✅ **代码复用性强**：ViewController 可以在不同流程中复用
4. ✅ **易于测试**：导航逻辑可以独立测试
5. ✅ **灵活性强**：可以动态切换导航流程
6. ✅ **解耦性好**：ViewController 之间无直接依赖

#### **Coordinator 模式的实现要点**

**1. 协调器树结构**
```
ApplicationCoordinator (根)
    ├── OnboardingCoordinator (子)
    └── WalletCoordinator (子)
```

**2. 生命周期管理**
```swift
// 添加子协调器
addChildCoordinator(walletCoordinator)
walletCoordinator.start()

// 移除子协调器
removeAllChildCoordinators()
```

**3. 通信机制**
```swift
// 通过 NotificationCenter 通信
NotificationCenter.default.post(name: .walletCreated, object: wallet)

// 通过回调函数通信
controller.onWalletImported = { wallet in ... }
```

**4. 依赖注入**
```swift
// 通过 AppContainer 注入依赖
let homeVM = WalletHomeViewModel(
    resolveBalancesUseCase: appContainer.resolveBalancesUseCase,
    fetchTxHistoryUseCase: appContainer.fetchTxHistoryUseCase
)
```

---

### 8.2 核心架构设计

#### **Coordinator 协议定义**

```swift
// Coordinator.swift
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }  // 子协调器列表
    var navigationController: UINavigationController { get set }  // 导航控制器
    
    func start()  // 开始协调器工作
    func finish()  // 结束协调器工作
}
```

**设计要点：**
- `childCoordinators`：管理子协调器，实现协调器树结构
- `navigationController`：持有导航控制器，负责页面跳转
- `start()`：启动协调器，展示初始页面
- `finish()`：清理资源，移除子协调器

#### **BaseCoordinator 基类实现**

```swift
// Coordinator.swift
class BaseCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        fatalError("start() method must be implemented")
        // 子类必须实现
    }
    
    func finish() {
        childCoordinators.removeAll()
        // 清理所有子协调器
    }
    
    /// 添加子协调器
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    /// 移除子协调器
    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
    
    /// 移除所有子协调器
    func removeAllChildCoordinators() {
        childCoordinators.removeAll()
    }
}
```

**设计要点：**
- **模板方法模式**：`start()` 由子类实现，`finish()` 提供默认实现
- **子协调器管理**：提供添加、移除、清空子协调器的方法
- **内存管理**：使用 `weak` 引用避免循环引用（通过 `!==` 比较）

---

### 8.3 Coordinator 层级结构

```
ApplicationCoordinator (根协调器)
    ├── OnboardingCoordinator (引导流程)
    │   ├── WelcomeViewController
    │   ├── CreateWalletViewController
    │   ├── MnemonicViewController
    │   └── ImportWalletViewController
    │
    └── WalletCoordinator (钱包主流程)
        ├── WalletHomeViewController
        ├── ReceiveViewController
        ├── SendViewController
        ├── TransactionHistoryViewController
        └── TransactionDetailViewController
```

---

### 8.4 ApplicationCoordinator（根协调器）详解

#### **职责**
- 应用启动时的入口选择
- 管理子协调器（OnboardingCoordinator、WalletCoordinator）
- 监听钱包创建/导入事件
- 决定应用初始流程（引导 or 钱包首页）

#### **完整实现解析**

```swift
// ApplicationCoordinator.swift
class ApplicationCoordinator: BaseCoordinator {
    private let disposeBag = DisposeBag()
    private let appContainer: AppContainer  // 依赖注入容器
    
    override init(navigationController: UINavigationController) {
        self.appContainer = AppContainer()  // 初始化依赖容器
        super.init(navigationController: navigationController)
    }
    
    override func start() {
        showEntrySelection()  // 显示入口选择页面
        setupWalletNotifications()  // 设置钱包事件监听
    }
}
```

#### **入口选择逻辑**

```swift
private func showEntrySelection() {
    let controller = EntrySelectionViewController()
    
    // 选择原生钱包
    controller.onSelectNative = { [weak self] in
        guard let self else { return }
        if WalletManagerSingleton.shared.hasWallets() {
            // 已有钱包，直接进入钱包首页
            self.showWalletHome()
        } else {
            // 没有钱包，进入引导流程
            self.showOnboarding()
        }
    }
    
    // 选择 React Native 钱包
    controller.onSelectReactNative = { [weak self] in
        self?.showReactNativeGateway()
    }
    
    navigationController.setViewControllers([controller], animated: false)
}
```

**执行流程：**
```
App 启动
  ↓
显示 EntrySelectionViewController
  ↓
用户选择"原生钱包"
  ↓
检查是否有钱包？
  ├─ 有 → showWalletHome()
  └─ 无 → showOnboarding()
```

#### **钱包事件监听**

```swift
private func setupWalletNotifications() {
    // 监听钱包创建事件
    NotificationCenter.default.rx
        .notification(.walletCreated)
        .subscribe(onNext: { [weak self] notification in
            self?.handleWalletCreated(notification.object as? Wallet)
        })
        .disposed(by: disposeBag)
    
    // 监听钱包导入事件
    NotificationCenter.default.rx
        .notification(.walletImported)
        .subscribe(onNext: { [weak self] notification in
            self?.handleWalletImported(notification.object as? Wallet)
        })
        .disposed(by: disposeBag)
}
```

**技术要点：**
- 使用 **RxSwift** 监听 `NotificationCenter`
- 使用 `[weak self]` 避免循环引用
- 通过 `Notification` 实现协调器间通信

#### **钱包创建/导入处理**

```swift
private func handleWalletCreated(_ wallet: Wallet?) {
    guard let wallet = wallet else { return }
    
    // 1. 添加到钱包管理器
    WalletManagerSingleton.shared.addWallet(wallet)
    
    // 2. 清理所有子协调器（结束引导流程）
    removeAllChildCoordinators()
    
    // 3. 切换到钱包首页
    showWalletHome(using: wallet)
}

private func showWalletHome(using walletOverride: Wallet? = nil) {
    // 优先级：传入钱包 > 当前钱包 > 第一个钱包
    let wallet = walletOverride
        ?? WalletManagerSingleton.shared.currentWalletSubject.value
        ?? WalletManagerSingleton.shared.allWalletsSubject.value.first
    
    guard let wallet else {
        // 没有钱包，回到引导流程
        showOnboarding()
        return
    }
    
    // 创建 WalletCoordinator
    let walletCoordinator = WalletCoordinator(
        navigationController: navigationController,
        wallet: wallet,
        appContainer: appContainer
    )
    
    // 添加为子协调器
    addChildCoordinator(walletCoordinator)
    
    // 启动协调器
    walletCoordinator.start()
}
```

**执行流程：**
```
用户创建钱包
  ↓
OnboardingCoordinator 发送 .walletCreated 通知
  ↓
ApplicationCoordinator 接收通知
  ↓
清理子协调器（结束引导流程）
  ↓
创建 WalletCoordinator
  ↓
启动 WalletCoordinator（显示钱包首页）
```

---

### 8.5 OnboardingCoordinator（引导流程）详解

#### **职责**
- 管理钱包创建/导入流程
- 展示 Welcome、CreateWallet、Mnemonic、ImportWallet 页面
- 通过 Notification 通知父协调器钱包创建/导入完成

#### **完整实现解析**

```swift
// OnboardingCoordinator.swift
class OnboardingCoordinator: BaseCoordinator {
    private let disposeBag = DisposeBag()
    
    override func start() {
        showWelcome()  // 显示欢迎页
    }
}
```

#### **欢迎页面流程**

```swift
private func showWelcome() {
    let welcomeVC = WelcomeViewController()
    let welcomeVM = WelcomeViewModel()
    welcomeVC.viewModel = welcomeVM
    
    // ✅ 使用 RxSwift Driver 绑定 ViewModel 输出到导航
    welcomeVM.output.showCreateWallet
        .drive(onNext: { [weak self] in
            self?.showCreateWallet()  // 导航到创建钱包页面
        })
        .disposed(by: disposeBag)
    
    welcomeVM.output.showImportWallet
        .drive(onNext: { [weak self] in
            self?.showImportWallet()  // 导航到导入钱包页面
        })
        .disposed(by: disposeBag)
    
    navigationController.setViewControllers([welcomeVC], animated: false)
}
```

**技术要点：**
- 使用 **Driver** 绑定 ViewModel 输出到导航操作
- `[weak self]` 避免循环引用
- `setViewControllers` 替换根视图控制器

#### **创建钱包流程**

```swift
private func showCreateWallet() {
    let createVC = CreateWalletViewController()
    let createVM = CreateWalletViewModel()
    createVC.viewModel = createVM
    
    // 绑定事件
    createVM.output.showMnemonic
        .drive(onNext: { [weak self] mnemonic in
            self?.showMnemonic(mnemonic: mnemonic)  // 显示助记词
        })
        .disposed(by: disposeBag)
    
    createVM.output.walletCreated
        .drive(onNext: { [weak self] wallet in
            self?.onWalletCreated(wallet: wallet)  // 钱包创建完成
        })
        .disposed(by: disposeBag)
    
    navigationController.pushViewController(createVC, animated: true)
}

private func showMnemonic(mnemonic: String) {
    let mnemonicVC = MnemonicViewController()
    let mnemonicVM = MnemonicViewModel(mnemonic: mnemonic)
    mnemonicVC.viewModel = mnemonicVM
    
    // 绑定钱包创建完成事件
    mnemonicVM.output.walletCreated
        .drive(onNext: { [weak self] wallet in
            self?.onWalletCreated(wallet: wallet)
        })
        .disposed(by: disposeBag)
    
    navigationController.pushViewController(mnemonicVC, animated: true)
}
```

**创建钱包流程：**
```
WelcomeViewController
  ↓ (用户点击"创建钱包")
CreateWalletViewController
  ↓ (生成助记词)
MnemonicViewController
  ↓ (用户确认助记词)
钱包创建完成 → 发送通知
```

#### **导入钱包流程**

```swift
private func showImportWallet() {
    let importVC = ImportWalletViewController()
    
    // 使用回调方式（非 RxSwift）
    importVC.onWalletImported = { [weak self] wallet in
        self?.onWalletImported(wallet: wallet)
    }
    
    navigationController.pushViewController(importVC, animated: true)
}
```

**导入钱包流程：**
```
WelcomeViewController
  ↓ (用户点击"导入钱包")
ImportWalletViewController
  ↓ (用户输入助记词)
钱包导入完成 → 回调触发 → 发送通知
```

#### **通知父协调器**

```swift
private func onWalletCreated(wallet: Wallet) {
    // 通过 NotificationCenter 通知父协调器
    NotificationCenter.default.post(name: .walletCreated, object: wallet)
}

private func onWalletImported(wallet: Wallet) {
    NotificationCenter.default.post(name: .walletImported, object: wallet)
}
```

**通信机制：**
- 使用 `NotificationCenter` 实现协调器间通信
- 子协调器发送通知，父协调器监听并处理
- 解耦协调器之间的直接依赖

---

### 8.6 WalletCoordinator（钱包主流程）详解

#### **职责**
- 管理钱包主功能页面（首页、发送、接收、交易历史）
- 处理币种选择（ETH/USDC/USDT）
- 依赖注入（通过 AppContainer）

#### **完整实现解析**

```swift
// WalletCoordinator.swift
class WalletCoordinator: BaseCoordinator {
    private let disposeBag = DisposeBag()
    private let wallet: Wallet  // 当前钱包
    private let appContainer: AppContainer  // 依赖容器
    
    init(navigationController: UINavigationController, 
         wallet: Wallet, 
         appContainer: AppContainer) {
        self.wallet = wallet
        self.appContainer = appContainer
        super.init(navigationController: navigationController)
    }
    
    override func start() {
        showWalletHome()  // 显示钱包首页
    }
}
```

#### **钱包首页设置**

```swift
private func showWalletHome() {
    let homeVC = WalletHomeViewController()
    let homeVM = WalletHomeViewModel(
        wallet: wallet,
        resolveBalancesUseCase: appContainer.resolveBalancesUseCase,  // 依赖注入
        fetchTxHistoryUseCase: appContainer.fetchTxHistoryUseCase,
        priceService: appContainer.priceService
    )
    homeVC.viewModel = homeVM
    homeVC.appContainer = appContainer
    
    // ✅ 绑定 ViewModel 输出到导航
    homeVM.output.showReceive
        .drive(onNext: { [weak self] wallet in
            self?.showReceive(wallet: wallet)
        })
        .disposed(by: disposeBag)
    
    homeVM.output.showSend
        .drive(onNext: { [weak self] wallet in
            self?.showSend(wallet: wallet)
        })
        .disposed(by: disposeBag)
    
    // ✅ 也可以直接绑定 UI 事件
    homeVC.sendButton.rx.tap
        .subscribe(onNext: { [weak self] in
            self?.showSend(wallet: self.wallet)
        })
        .disposed(by: disposeBag)
    
    navigationController.setViewControllers([homeVC], animated: false)
}
```

**技术要点：**
- **依赖注入**：通过 `appContainer` 注入 UseCase 和服务
- **双重绑定**：既绑定 ViewModel 输出，也直接绑定 UI 事件
- **RxSwift 集成**：使用 Driver 和 ControlEvent 进行响应式导航

#### **发送页面流程（包含币种选择）**

```swift
private func showSend(wallet: Wallet) {
    // 先显示币种选择
    showCurrencySelection(for: wallet)
}

private func showCurrencySelection(for wallet: Wallet) {
    let alert = UIAlertController(
        title: "Select Currency", 
        message: "Choose the currency you want to send", 
        preferredStyle: .actionSheet
    )
    
    // ETH 选项
    alert.addAction(UIAlertAction(title: "ETH", style: .default) { [weak self] _ in
        self?.showSendViewController(wallet: wallet, currency: Currency.eth)
    })
    
    // USDC 选项
    alert.addAction(UIAlertAction(title: "USDC", style: .default) { [weak self] _ in
        self?.showSendViewController(wallet: wallet, currency: Currency.usdc)
    })
    
    // USDT 选项
    alert.addAction(UIAlertAction(title: "USDT", style: .default) { [weak self] _ in
        self?.showSendViewController(wallet: wallet, currency: Currency.usdt)
    })
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    navigationController.present(alert, animated: true)
}

private func showSendViewController(wallet: Wallet, currency: Currency) {
    let sendVC = SendViewController()
    
    // 创建 SendTransactionUseCase
    let sendTransactionUseCase = SendTransactionUseCase(
        ethereumService: appContainer.ethereumService
    )
    
    // 获取当前钱包（从 WalletManagerSingleton）
    guard let currentWallet = WalletManagerSingleton.shared.currentWalletSubject.value else {
        return
    }
    
    // 创建 ViewModel（依赖注入）
    let sendVM = SendViewModel(
        wallet: currentWallet,
        estimateGasUseCase: appContainer.estimateGasUseCase,
        ethereumService: appContainer.ethereumService,
        sendTransactionUseCase: sendTransactionUseCase,
        selectedCurrency: currency
    )
    sendVC.viewModel = sendVM
    
    navigationController.pushViewController(sendVC, animated: true)
}
```

**发送流程：**
```
WalletHomeViewController
  ↓ (用户点击"发送")
显示币种选择 Alert
  ↓ (用户选择币种，如 ETH)
SendViewController
```

---

### 8.7 Coordinator 生命周期管理

#### **协调器树结构**

```
ApplicationCoordinator
    └── childCoordinators: [
            OnboardingCoordinator,
            WalletCoordinator
        ]
```

#### **添加子协调器**

```swift
// ApplicationCoordinator.swift
private func showOnboarding() {
    let onboardingCoordinator = OnboardingCoordinator(
        navigationController: navigationController
    )
    
    // ✅ 添加为子协调器
    addChildCoordinator(onboardingCoordinator)
    
    // 启动协调器
    onboardingCoordinator.start()
}
```

#### **移除子协调器**

```swift
// ApplicationCoordinator.swift
private func handleWalletCreated(_ wallet: Wallet?) {
    // ✅ 清理所有子协调器（结束引导流程）
    removeAllChildCoordinators()
    
    // 切换到钱包首页
    showWalletHome(using: wallet)
}
```

**内存管理：**
- 父协调器持有子协调器的强引用
- 子协调器通过 `finish()` 清理资源
- 使用 `removeAllChildCoordinators()` 批量清理

---

### 8.8 Coordinator 与 RxSwift 集成

#### **使用 Driver 绑定导航**

```swift
// OnboardingCoordinator.swift
welcomeVM.output.showCreateWallet
    .drive(onNext: { [weak self] in
        self?.showCreateWallet()
    })
    .disposed(by: disposeBag)
```

**优势：**
- **线程安全**：Driver 保证在主线程执行
- **不发送错误**：Driver 不会发送 onError
- **自动共享**：避免重复订阅

#### **使用 ControlEvent 绑定 UI 事件**

```swift
// WalletCoordinator.swift
homeVC.sendButton.rx.tap
    .subscribe(onNext: { [weak self] in
        self?.showSend(wallet: self.wallet)
    })
    .disposed(by: disposeBag)
```

**优势：**
- **声明式编程**：代码更简洁
- **自动管理**：通过 `disposed(by: disposeBag)` 自动释放

#### **使用 NotificationCenter 通信**

```swift
// OnboardingCoordinator.swift（发送通知）
NotificationCenter.default.post(name: .walletCreated, object: wallet)

// ApplicationCoordinator.swift（接收通知）
NotificationCenter.default.rx
    .notification(.walletCreated)
    .subscribe(onNext: { [weak self] notification in
        self?.handleWalletCreated(notification.object as? Wallet)
    })
    .disposed(by: disposeBag)
```

**优势：**
- **解耦**：协调器之间不直接依赖
- **灵活**：可以一对多通信
- **RxSwift 集成**：使用 `.rx.notification` 进行响应式处理

---

### 8.9 Coordinator 模式最佳实践

#### **1. 职责分离**

```swift
// ✅ 正确：Coordinator 负责导航
coordinator.showSend(wallet: wallet)

// ❌ 错误：ViewController 直接导航
navigationController.pushViewController(sendVC, animated: true)
```

#### **2. 依赖注入**

```swift
// ✅ 正确：通过 AppContainer 注入依赖
let homeVM = WalletHomeViewModel(
    wallet: wallet,
    resolveBalancesUseCase: appContainer.resolveBalancesUseCase,
    fetchTxHistoryUseCase: appContainer.fetchTxHistoryUseCase,
    priceService: appContainer.priceService
)

// ❌ 错误：在 ViewModel 内部创建依赖
let homeVM = WalletHomeViewModel()  // 内部创建依赖
```

#### **3. 生命周期管理**

```swift
// ✅ 正确：添加子协调器
addChildCoordinator(walletCoordinator)
walletCoordinator.start()

// ✅ 正确：清理子协调器
removeAllChildCoordinators()
```

#### **4. 内存管理**

```swift
// ✅ 正确：使用 weak self
.drive(onNext: { [weak self] in
    self?.showSend()
})

// ✅ 正确：使用 disposeBag
.disposed(by: disposeBag)
```

---

### 8.10 Coordinator 模式总结

| 特性 | 说明 |
|------|------|
| **职责** | 管理导航流程，不处理业务逻辑 |
| **层级** | 树形结构，父协调器管理子协调器 |
| **通信** | 通过 NotificationCenter 或回调 |
| **依赖注入** | 通过 AppContainer 统一管理 |
| **RxSwift 集成** | 使用 Driver 和 ControlEvent 绑定 |
| **生命周期** | 通过 start/finish 管理 |

**优势：**
1. ✅ 导航逻辑集中管理
2. ✅ ViewController 可复用
3. ✅ 易于测试导航流程
4. ✅ 代码结构清晰

**适用场景：**
- 复杂的导航流程
- 需要动态切换导航逻辑
- 需要测试导航流程
- 多个 ViewController 共享导航逻辑

---

## 📚 九、总结

### 核心代码文件清单

**钱包管理：**
- `GenerateMnemonicUseCase.swift` - 生成助记词
- `ImportWalletUseCase.swift` - 导入钱包
- `WalletManagementViewModel.swift` - 钱包管理 ViewModel

**资产管理：**
- `ResolveBalancesUseCase.swift` - 余额解析
- `EthereumService.swift` - 以太坊服务
- `WalletHomeViewModel.swift` - 钱包首页 ViewModel

**交易历史：**
- `FetchTxHistoryUseCase.swift` - 获取交易历史
- `TransactionHistoryViewModel.swift` - 交易历史 ViewModel

**发送交易：**
- `SendTransactionUseCase.swift` - 发送交易用例
- `SendViewModel.swift` - 发送页面 ViewModel
- `EstimateGasUseCase.swift` - Gas 估算

### RxSwift 核心用法总结

1. **Observable 创建**: 封装异步操作（网络、存储）
2. **操作符链式调用**: combineLatest（并行）、zip（并行对应）、flatMap（链式依赖）
3. **UI 绑定**: RxCocoa 的按钮、表格、文本绑定
4. **状态管理**: BehaviorRelay + Driver 模式
5. **错误处理**: catch、onErrorJustReturn
6. **性能优化**: debounce（防抖）、delay（延迟）、缓存

这个项目是学习 **RxSwift 在实际 iOS 项目中的应用** 的绝佳示例，涵盖了日常开发中的大部分使用场景。
