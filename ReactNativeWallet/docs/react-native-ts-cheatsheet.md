# React Native + TypeScript 学习速查表

本文结合 Trust Wallet RN 客户端的真实代码，总结 React / React Native 与 TypeScript 的核心概念与用法。适合希望快速入门的开发者。

---

## 1. 组件基础：函数式组件与 JSX

React 建议使用函数式组件 + Hooks。函数返回 JSX，即类似 HTML 的 UI 描述。

```tsx
import React from 'react';
import { Text, View } from 'react-native';

export function HelloCard(): React.ReactElement {
  return (
    <View style={{ padding: 16, backgroundColor: '#111827', borderRadius: 16 }}>
      <Text style={{ color: '#f9fafb', fontSize: 20, fontWeight: '700' }}>
        Hello Wallet!
      </Text>
    </View>
  );
}
```

> **JSX 内嵌所有 React 组件/原生控件**：`<View>` 类似 `<div>`，`<Text>` 类似 `<p>`。React Native 不支持 DOM 标签，需使用 RN 提供的组件。

---

## 2. useState：组件内部状态

`useState` 用于声明状态变量；类型由初值推断，也可显式声明。

```tsx
const [amount, setAmount] = useState<string>(''); // 初始值为 ''，类型为 string

const handleChangeAmount = (value: string) => {
  // TypeScript 自动提示 value 的类型
  setAmount(value.trim());
};
```

### 实际案例：发送页金额输入

`SendScreen` 中使用 `useState` 记录用户输入：

```tsx
const [amount, setAmount] = useState('');

<TextInput
  value={amount}
  onChangeText={setAmount}
  keyboardType="decimal-pad"
/>
```

> **Tips**：如果状态是对象/数组，更新时要注意不可变数据（使用扩展运算符等）。

---

## 3. useRef：可变引用 & 与原生交互

`useRef` 创建一个跨渲染周期持久的可变对象，常用于：
- 保存计时器/缓存
- 获取原生组件引用
- 存取历史值（不会触发重新渲染）

```tsx
const estimateCache = useRef<Map<string, { timestamp: number; estimate: GasEstimate }>>(new Map());

// 读取/写入
const cached = estimateCache.current.get(cacheKey);
estimateCache.current.set(cacheKey, { timestamp: Date.now(), estimate });
```

### 实际案例：Gas 估算缓存

`SendScreen` 中用 `useRef` 保存 5 秒内的 gas 估算结果，避免频繁 API 请求。

> **注意**：`ref.current` 改变时不会触发重新渲染，如果需要更新 UI，应配合 `useState`。

---

## 4. useEffect / useFocusEffect：副作用

副作用指与渲染无关的操作：数据请求、订阅、定时器等。React 提供 `useEffect`；React Navigation 额外提供 `useFocusEffect` 处理页面 focus 事件。

```tsx
useEffect(() => {
  initialize(); // 首次挂载时加载数据
}, [initialize]);
```

```tsx
useFocusEffect(
  useCallback(() => {
    refreshBalances({ force: true });
  }, [refreshBalances]),
);
```

> **清理函数**：返回一个函数，可在组件卸载或依赖改变时执行清理（如取消订阅）。

---

## 5. useMemo / useCallback：性能优化

- `useMemo(fn, deps)`：缓存计算结果；只有依赖变化才重新计算。
- `useCallback(fn, deps)`：缓存函数，防止子组件重复渲染或用于 `useEffect` 依赖。

```tsx
const selectedCurrency = useMemo(() => {
  return SUPPORTED_CURRENCIES.find(c => c.symbol === routeCurrencySymbol);
}, [routeCurrencySymbol]);

const renderItem = useCallback(({ item }: ListRenderItemInfo<Transaction>) => {
  /* ... */
}, []);
```

---

## 6. 全局状态：Zustand store

Zustand 是轻量状态库。创建 store 时定义类型、初始状态和操作函数。组件通过 hook 直接读取和调用。

```ts
type WalletState = {
  balances: Balance[];
  loadingBalances: boolean;
  refreshBalances: (options?: { force?: boolean }) => Promise<void>;
};

export const useWalletStore = create<WalletState>((set, get) => ({
  balances: [],
  loadingBalances: false,
  async refreshBalances(options) {
    /* ... */
  },
}));
```

```tsx
const balances = useWalletStore(state => state.balances);
const refreshBalances = useWalletStore(state => state.refreshBalances);
```

> **技巧**：Zustand 的 selector (state => state.xxx) 会减少无关状态更新导致的重渲染。

---

## 7. TypeScript 核心概念

### 7.1 类型别名 & 联合类型

```ts
export type TransactionStatus = 'pending' | 'success' | 'failed';

export type GasEstimate = {
  gasLimit: bigint;
  gasPriceWei: bigint;
  maxFeePerGasWei?: bigint;
  maxPriorityFeePerGasWei?: bigint;
  feeWei: bigint;
};
```

`status` 只能是三种字符串之一，编译器可推断 switch/if 分支。`?` 表示可选字段。

### 7.2 函数类型

```ts
type RefreshOptions = { force?: boolean };

refreshTransactions(options?: RefreshOptions): Promise<void>;
```

可选参数默认 `undefined`；调用时有类型提示：

```tsx
await refreshTransactions({ force: true });
```

### 7.3 泛型与类型推断

Axios、FlatList 等库大量使用泛型。自定义泛型函数：

```ts
function getItem<T>(key: string): Promise<T | null>;
```

调用时指定类型：

```ts
const wallets = await getItem<Wallet[]>(WALLETS_KEY);
```

### 7.4 类型守卫

当 API 响应类型不可靠时，可自己做守卫：

```ts
if (response?.status === '1' && Array.isArray(response.result)) {
  return response.result as Transaction[];
}
console.warn('Unexpected response', response);
return [];
```

---

## 8. React Native 常用组件与技巧

### 8.1 `FlatList` + `RefreshControl`

```tsx
<FlatList
  data={balances}
  keyExtractor={item => item.currency.symbol}
  renderItem={renderItem}
  refreshControl={
    <RefreshControl
      refreshing={loadingBalances}
      onRefresh={() => refreshBalances({ force: true })}
      tintColor="#6366f1"
      progressViewOffset={insets.top + 16}
    />
  }
/>
```

`progressViewOffset` 可让菊花在安全区域下方显示。

### 8.2 `Pressable` 替换 `TouchableOpacity`

```tsx
<Pressable
  style={({ pressed }) => [
    styles.button,
    !canSend && styles.buttonDisabled,
    pressed && canSend && styles.buttonPressed,
  ]}
  onPress={handleSend}
  disabled={!canSend}>
  <Text style={styles.buttonText}>Send Transaction</Text>
</Pressable>
```

使用回调获取 `pressed` 状态，配合样式实现点击反馈。

---

## 9. 结合钱包项目的实战练习建议

1. **仿写一个资产卡片组件**：使用 `useState` 控制是否显示明细，利用 TypeScript 为 props 定义类型。  
2. **新增一个下拉刷新列表**：照着 Activity/Home，练习 `RefreshControl` + Zustand 强制刷新。  
3. **实现自定义 Hook**：例如 `useDebouncedEffect`，封装发送页的输入防抖逻辑，加深对 `useEffect` 与 `useRef` 的理解。  
4. **扩展 store**：添加“最近使用的地址”列表，感受 TypeScript 对数据结构的约束与 IDE 自动补全的好处。

---

## 10. 推荐学习路径

1. **官方文档**：React (`react.dev`)、React Native (`reactnative.dev`) 与 TypeScript Handbook。  
2. **工具链**：了解 Metro、Babel、ESLint、prettier；尝试调试 Flipper。  
3. **测试与调试**：结合 `jest` + `@testing-library/react-native` 编写组件测试；学会使用 React DevTools、Hermes Profiling。  
4. **原生模块**：进一步了解 React Native Bridge，在 wallet 项目中可以和 Swift/Java 模块交互实现链上签名或硬件功能。

---

掌握以上内容，再配合项目中已经落地的功能（钱包导入、资产刷新、交易列表、发送流程），你可以快速上手 React Native + TypeScript 的实际开发，并逐步扩展到更多复杂场景。祝学习顺利!
