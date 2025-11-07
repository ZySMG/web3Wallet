import React, { useCallback } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Linking,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import Feather from 'react-native-vector-icons/Feather';
import { useFocusEffect } from '@react-navigation/native';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { useWalletStore } from '@presentation/state/walletStore';
import { formatTransactionAmount } from '@domain/entities/Transaction';
import type { Transaction } from '@domain/entities/Transaction';
import type { ListRenderItemInfo } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export function ActivityScreen(): React.JSX.Element {
  const insets = useSafeAreaInsets();
  const activeWallet = useWalletStore(state => state.activeWallet);
  const transactions = useWalletStore(state => state.transactions);
  const loadingTransactions = useWalletStore(state => state.loadingTransactions);
  const refreshTransactions = useWalletStore(state => state.refreshTransactions);

  const handleRefresh = useCallback(
    async (force = false) => {
      try {
        await refreshTransactions({ force });
      } catch (error) {
        console.warn('[ActivityScreen] Failed to refresh transactions', error);
      }
    },
    [refreshTransactions],
  );

  useFocusEffect(
    useCallback(() => {
      handleRefresh(true);
    }, [handleRefresh]),
  );
  const renderItem = useCallback(
    ({ item }: ListRenderItemInfo<Transaction>) => (
      <TouchableOpacity
        style={styles.txRow}
        onPress={() => Linking.openURL(`${item.network.explorerBaseUrl}/tx/${item.hash}`)}>
        <View
          style={[styles.iconContainer, item.direction === 'inbound' ? styles.inbound : styles.outbound]}>
          <Feather
            name={item.direction === 'inbound' ? 'arrow-down-left' : 'arrow-up-right'}
            size={18}
            color={item.direction === 'inbound' ? '#10b981' : '#ef4444'}
          />
        </View>
        <View style={styles.txInfo}>
          <Text style={styles.txAmount}>{formatTransactionAmount(item)}</Text>
          <Text style={styles.txHash}>{shortenHash(item.hash)}</Text>
        </View>
        <View style={styles.txMeta}>
          <Text style={styles.txStatus}>{item.status.toUpperCase()}</Text>
          <Text style={styles.txDate}>{formatTimestamp(item.timestamp)}</Text>
        </View>
      </TouchableOpacity>
    ),
    [],
  );

  const renderEmpty = useCallback(
    () => (
      <View style={styles.emptyList}>
        {loadingTransactions ? (
          <ActivityIndicator color="#6366f1" />
        ) : (
          <Text style={styles.emptyBalanceText}>No transactions yet</Text>
        )}
      </View>
    ),
    [loadingTransactions],
  );

  if (!activeWallet) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyTitle}>No wallet selected</Text>
        <Text style={styles.emptySubtitle}>
          Create or import a wallet to view your transaction history.
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={transactions}
        keyExtractor={item => item.hash}
        refreshControl={
          <RefreshControl
            refreshing={loadingTransactions}
            onRefresh={async () => {
              try {
                await handleRefresh(true);
              } finally {
                // no-op: refresh control will stop when loadingTransactions flips
              }
            }}
            tintColor="#6366f1"
            title={loadingTransactions ? 'Refreshing…' : undefined}
            titleColor="#9ca3af"
            progressViewOffset={insets.top + 12}
          />
        }
        contentContainerStyle={[
          styles.listContent,
          { paddingTop: insets.top + 24 },
        ]}
        ListEmptyComponent={renderEmpty}
        renderItem={renderItem}
      />
    </View>
  );
}

function shortenHash(hash: string): string {
  return `${hash.slice(0, 6)}…${hash.slice(-4)}`;
}

function formatTimestamp(timestamp: string): string {
  const date = new Date(timestamp);
  return `${date.toLocaleDateString()} ${date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#05070f',
  },
  listContent: {
    padding: 24,
  },
  txRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#111827',
    borderRadius: 18,
    padding: 16,
    marginBottom: 16,
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  inbound: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
  },
  outbound: {
    backgroundColor: 'rgba(239, 68, 68, 0.15)',
  },
  txInfo: {
    flex: 1,
  },
  txAmount: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  txHash: {
    color: '#9ca3af',
    marginTop: 4,
    fontSize: 13,
  },
  txMeta: {
    alignItems: 'flex-end',
  },
  txStatus: {
    color: '#818cf8',
    fontWeight: '600',
    fontSize: 12,
  },
  txDate: {
    color: '#9ca3af',
    marginTop: 4,
    fontSize: 12,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
    backgroundColor: '#05070f',
  },
  emptyTitle: {
    color: '#f9fafb',
    fontSize: 22,
    fontWeight: '700',
    marginBottom: 12,
  },
  emptySubtitle: {
    color: '#9ca3af',
    fontSize: 16,
    textAlign: 'center',
  },
  emptyList: {
    paddingVertical: 48,
    alignItems: 'center',
  },
  emptyBalanceText: {
    color: '#9ca3af',
  },
});
