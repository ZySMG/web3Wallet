import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { useNavigation, useRoute } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RouteProp } from '@react-navigation/native';
import { SUPPORTED_CURRENCIES } from '@domain/entities/Currency';
import type { Currency } from '@domain/entities/Currency';
import type { RootStackParamList } from '@app/navigation/types';
import { useWalletStore } from '@presentation/state/walletStore';
import type { GasEstimate } from '@domain/entities/GasEstimate';
import { calculateFeeInEth } from '@domain/usecases/estimateGas';
import { formatUnits } from 'ethers';

export function SendScreen(): React.JSX.Element {
  const navigation =
    useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const route = useRoute<RouteProp<RootStackParamList, 'Send'>>();
  const routeCurrencySymbol = route.params?.currencySymbol;
  const estimateGas = useWalletStore(state => state.estimateGas);
  const sendTransaction = useWalletStore(state => state.sendTransaction);
  const balances = useWalletStore(state => state.balances);

  const selectedCurrency = useMemo<Currency | undefined>(() => {
    if (!routeCurrencySymbol) {
      return undefined;
    }
    return SUPPORTED_CURRENCIES.find(currency => currency.symbol === routeCurrencySymbol);
  }, [routeCurrencySymbol]);
  const [toAddress, setToAddress] = useState('');
  const [amount, setAmount] = useState('');
  const [isEstimating, setIsEstimating] = useState(false);
  const [gasEstimate, setGasEstimate] = useState<GasEstimate | undefined>(undefined);
  const [sending, setSending] = useState(false);
  const estimateCache = useRef<
    Map<
      string,
      {
        timestamp: number;
        estimate: GasEstimate;
      }
    >
  >(new Map());

  const ethBalance = useMemo(
    () => balances.find(balance => balance.currency.symbol === 'ETH'),
    [balances],
  );

  const selectedBalance = useMemo(() => {
    if (!selectedCurrency) {
      return undefined;
    }
    return balances.find(
      balance => balance.currency.symbol === selectedCurrency.symbol,
    );
  }, [balances, selectedCurrency]);

  useEffect(() => {
    if (!routeCurrencySymbol || !selectedCurrency) {
      navigation.replace('SelectToken', { returnTo: 'Send' });
    }
  }, [navigation, routeCurrencySymbol, selectedCurrency]);

  const sanitizedAddress = toAddress.trim();
  const sanitizedAmount = amount.trim();
  const recipientLength = sanitizedAddress.length;
  const amountValue = sanitizedAmount.length > 0 ? Number.parseFloat(sanitizedAmount) : NaN;
  const hasAmount = Number.isFinite(amountValue) && amountValue > 0;
  const tokenBalanceValue = Number.parseFloat(selectedBalance?.amount ?? '0');
  const ethBalanceValue = Number.parseFloat(ethBalance?.amount ?? '0');
  const feeEthValue = gasEstimate
    ? Number.parseFloat(calculateFeeInEth(gasEstimate))
    : NaN;
  const hasFeeValue = Number.isFinite(feeEthValue);
  const isTokenTransfer = Boolean(selectedCurrency?.contractAddress);
  const EPSILON = 1e-9;
  const tokenSufficient =
    selectedCurrency && hasAmount && hasFeeValue
      ? isTokenTransfer
        ? amountValue <= tokenBalanceValue + EPSILON
        : amountValue + feeEthValue <= tokenBalanceValue + EPSILON
      : false;
  const gasSufficient =
    selectedCurrency && hasFeeValue
      ? isTokenTransfer
        ? feeEthValue <= ethBalanceValue + EPSILON
        : amountValue + feeEthValue <= ethBalanceValue + EPSILON
      : false;
  const hasRecipient = recipientLength > 0;
  const recipientValid = recipientLength === 42 && isValidAddress(sanitizedAddress);
  const feeDisplay = hasFeeValue ? formatEth(feeEthValue) : undefined;
  const gasLimitDisplay = gasEstimate
    ? Number(gasEstimate.gasLimit).toLocaleString()
    : undefined;
  const gasPriceDisplay = gasEstimate ? formatGwei(gasEstimate.gasPriceWei) : undefined;
  const maxFeeDisplay = gasEstimate?.maxFeePerGasWei
    ? formatGwei(gasEstimate.maxFeePerGasWei)
    : undefined;
  const priorityDisplay = gasEstimate?.maxPriorityFeePerGasWei
    ? formatGwei(gasEstimate.maxPriorityFeePerGasWei)
    : undefined;

  const validationMessages: string[] = [];
  if (recipientLength >= 42 && !recipientValid) {
    validationMessages.push('Recipient address is invalid.');
  }
  if (selectedCurrency && hasAmount && gasEstimate) {
    if (!tokenSufficient) {
      validationMessages.push(
        selectedCurrency.symbol === 'ETH'
          ? 'Amount plus network fee exceeds your available ETH balance.'
          : 'Amount exceeds your available balance for this token.',
      );
    }
    if (!gasSufficient && isTokenTransfer) {
      validationMessages.push('Not enough ETH to cover the network fee.');
    }
  }

  const canSend = Boolean(
    selectedCurrency &&
      recipientValid &&
      hasAmount &&
      gasEstimate &&
      hasFeeValue &&
      !isEstimating &&
      tokenSufficient &&
      gasSufficient &&
      !sending,
  );

  useEffect(() => {
    if (!selectedCurrency) {
      setGasEstimate(undefined);
      setIsEstimating(false);
      return;
    }

    if (!isValidAddress(sanitizedAddress) || Number(sanitizedAmount) <= 0) {
      setGasEstimate(undefined);
      setIsEstimating(false);
      return;
    }
    const cacheKey = `${selectedCurrency.symbol}:${sanitizedAddress.toLowerCase()}:${sanitizedAmount}`;
    let cancelled = false;
    let requestActive = false;
    const debounceId = setTimeout(() => {
      if (cancelled) {
        return;
      }
      const now = Date.now();
      const cached = estimateCache.current.get(cacheKey);
      if (cached && now - cached.timestamp < 5000) {
        setGasEstimate(cached.estimate);
        setIsEstimating(false);
        return;
      }
      requestActive = true;
      setIsEstimating(true);
      estimateGas({
        to: sanitizedAddress,
        amount: sanitizedAmount,
        currency: selectedCurrency,
      })
        .then(estimate => {
          if (!cancelled) {
            estimateCache.current.set(cacheKey, { estimate, timestamp: Date.now() });
            setGasEstimate(estimate);
          }
        })
        .catch(() => {
          if (!cancelled) {
            setGasEstimate(undefined);
          }
        })
        .finally(() => {
          if (!cancelled) {
            setIsEstimating(false);
          }
        });
    }, 600);
    return () => {
      cancelled = true;
      if (requestActive) {
        setIsEstimating(false);
      }
      clearTimeout(debounceId);
    };
  }, [sanitizedAddress, sanitizedAmount, selectedCurrency, estimateGas]);

  const handleChangeToken = () => {
    navigation.replace('SelectToken', {
      returnTo: 'Send',
      selectedSymbol: selectedCurrency?.symbol,
    });
  };

  const handleSend = () => {
    if (!selectedCurrency) {
      return;
    }
    if (!recipientValid || !hasAmount) {
      Alert.alert('Missing data', 'Please fill in recipient and amount.');
      return;
    }
    setSending(true);
    sendTransaction({
      to: sanitizedAddress,
      amount: sanitizedAmount,
      currency: selectedCurrency,
      gasEstimate,
    })
      .then(hash => {
        Alert.alert('Transaction sent', `Hash: ${hash}`);
        navigation.goBack();
      })
      .catch(error => {
        Alert.alert('Unable to send', error.message ?? 'Unexpected error');
      })
      .finally(() => setSending(false));
  };

  if (!selectedCurrency) {
    return null;
  }

  const availableText = `${selectedBalance?.amount ?? '0'} ${selectedCurrency.symbol}`;
  const ethBalanceText = `${ethBalance?.amount ?? '0'} ETH`;
  const feeInfoText = isTokenTransfer
    ? `Network fee will consume ETH balance (${ethBalanceText}).`
    : 'Network fee will be deducted from this balance.';
  const maxSendableValue =
    selectedCurrency && hasFeeValue
      ? isTokenTransfer
        ? tokenBalanceValue
        : Math.max(tokenBalanceValue - feeEthValue, 0)
      : tokenBalanceValue;
  const maxSendableText =
    selectedCurrency && Number.isFinite(maxSendableValue)
      ? `${formatTokenAmount(maxSendableValue, selectedCurrency.decimals)} ${
          selectedCurrency.symbol
        }`
      : availableText;

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.select({ ios: 'padding', android: undefined })}>
      <ScrollView contentContainerStyle={styles.container}>
        <Text style={styles.title}>Send Tokens</Text>
        <View style={styles.tokenHeader}>
          <View>
            <Text style={styles.label}>Token</Text>
            <Text style={styles.selectedToken}>{selectedCurrency.symbol}</Text>
            <Text style={styles.tokenName}>{selectedCurrency.name}</Text>
            <Text style={styles.balanceText}>Available: {availableText}</Text>
            <Text style={styles.balanceSubtle}>{feeInfoText}</Text>
          </View>
          <TouchableOpacity style={styles.changeTokenButton} onPress={handleChangeToken}>
            <Text style={styles.changeTokenText}>Change</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.label}>Recipient</Text>
        <TextInput
          style={styles.input}
          value={toAddress}
          onChangeText={setToAddress}
          placeholder="0x..."
          placeholderTextColor="#6b7280"
          autoCapitalize="none"
          autoCorrect={false}
        />

        <View style={styles.inputHeaderRow}>
          <Text style={styles.label}>Amount</Text>
          <Text style={styles.balanceHint}>Max: {maxSendableText}</Text>
        </View>
        <TextInput
          style={styles.input}
          value={amount}
          onChangeText={setAmount}
          keyboardType="decimal-pad"
          placeholder="0.0"
          placeholderTextColor="#6b7280"
        />

        <View style={styles.gasCard}>
          <View style={styles.gasHeaderRow}>
            <Text style={styles.gasLabel}>Network Fee</Text>
            {isEstimating && <ActivityIndicator size="small" color="#9ca3af" />}
          </View>
          <Text style={styles.gasValue}>
            {gasEstimate
              ? `${feeDisplay ?? '--'} ETH`
              : isEstimating
              ? 'Estimating…'
              : 'Enter recipient and amount'}
          </Text>
          {gasEstimate && (
            <View style={styles.gasDetails}>
              <Text style={styles.gasDetailText}>
                Gas limit: {gasLimitDisplay ?? '--'}
              </Text>
              <Text style={styles.gasDetailText}>
                Gas price: {gasPriceDisplay ?? '--'} gwei
              </Text>
              {maxFeeDisplay && (
                <Text style={styles.gasDetailText}>
                  Max fee per gas: {maxFeeDisplay} gwei
                </Text>
              )}
              {priorityDisplay && (
                <Text style={styles.gasDetailText}>
                  Priority fee: {priorityDisplay} gwei
                </Text>
              )}
            </View>
          )}
        </View>

        {validationMessages.length > 0 && (
          <View style={styles.validationContainer}>
            {validationMessages.map((message, index) => (
              <Text
                key={`${message}-${index}`}
                style={[
                  styles.validationText,
                  index === validationMessages.length - 1 && styles.validationTextLast,
                ]}>
                {message}
              </Text>
            ))}
          </View>
        )}

        <Pressable
          style={({ pressed }) => [
            styles.button,
            !canSend && styles.buttonDisabled,
            pressed && canSend && styles.buttonPressed,
          ]}
          onPress={handleSend}
          disabled={!canSend}>
          <Text style={styles.buttonText}>{sending ? 'Sending…' : 'Send Transaction'}</Text>
        </Pressable>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function isValidAddress(address: string): boolean {
  return /^0x[a-fA-F0-9]{40}$/.test(address.trim());
}

function formatEth(value: number): string {
  if (!Number.isFinite(value)) {
    return '--';
  }
  if (value === 0) {
    return '0';
  }
  if (value >= 0.01) {
    return value.toFixed(4);
  }
  if (value >= 0.0001) {
    return value.toFixed(6);
  }
  return value.toFixed(8);
}

function formatGwei(wei?: bigint): string | undefined {
  if (wei === undefined) {
    return undefined;
  }
  const value = Number.parseFloat(formatUnits(wei, 9));
  if (!Number.isFinite(value)) {
    return undefined;
  }
  if (value >= 10) {
    return value.toFixed(1);
  }
  if (value >= 1) {
    return value.toFixed(2);
  }
  return value.toFixed(4);
}

function formatTokenAmount(value: number, decimals: number): string {
  if (!Number.isFinite(value) || value === 0) {
    return '0';
  }
  const precision = value >= 1 ? Math.min(decimals, 4) : Math.min(decimals, 6);
  return value.toFixed(precision).replace(/\.?0+$/, '');
}

const styles = StyleSheet.create({
  flex: {
    flex: 1,
    backgroundColor: '#05070f',
  },
  container: {
    flexGrow: 1,
    padding: 24,
  },
  title: {
    color: '#f9fafb',
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 24,
  },
  label: {
    color: '#9ca3af',
    fontSize: 14,
    marginBottom: 8,
  },
  tokenHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    padding: 16,
    borderRadius: 16,
    backgroundColor: '#111827',
    marginBottom: 24,
  },
  selectedToken: {
    color: '#f9fafb',
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 4,
  },
  tokenName: {
    color: '#9ca3af',
    fontSize: 13,
    marginBottom: 6,
  },
  balanceText: {
    color: '#f9fafb',
    fontSize: 14,
    marginBottom: 4,
  },
  balanceSubtle: {
    color: '#9ca3af',
    fontSize: 12,
    maxWidth: 220,
  },
  changeTokenButton: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 12,
    backgroundColor: '#1f2937',
  },
  changeTokenText: {
    color: '#818cf8',
    fontWeight: '600',
  },
  input: {
    backgroundColor: '#111827',
    color: '#f9fafb',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderRadius: 16,
    fontSize: 16,
    marginBottom: 20,
  },
  inputHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  balanceHint: {
    color: '#6b7280',
    fontSize: 12,
  },
  gasCard: {
    backgroundColor: '#111827',
    borderRadius: 18,
    padding: 16,
    marginBottom: 24,
  },
  gasHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  gasLabel: {
    color: '#9ca3af',
    fontSize: 14,
  },
  gasValue: {
    color: '#f9fafb',
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12,
  },
  gasDetails: {
    marginTop: 4,
  },
  gasDetailText: {
    color: '#9ca3af',
    fontSize: 13,
    marginBottom: 4,
  },
  validationContainer: {
    backgroundColor: 'rgba(239, 68, 68, 0.12)',
    borderRadius: 12,
    padding: 12,
    marginBottom: 16,
  },
  validationText: {
    color: '#fca5a5',
    fontSize: 13,
    marginBottom: 4,
  },
  validationTextLast: {
    marginBottom: 0,
  },
  button: {
    backgroundColor: '#6366f1',
    paddingVertical: 16,
    borderRadius: 16,
    alignItems: 'center',
  },
  buttonDisabled: {
    backgroundColor: '#4f46e5',
    opacity: 0.7,
  },
  buttonPressed: {
    opacity: 0.85,
  },
  buttonText: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
});
