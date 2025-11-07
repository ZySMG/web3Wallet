import React, { useCallback, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import Clipboard from '@react-native-clipboard/clipboard';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import Feather from 'react-native-vector-icons/Feather';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { useWalletStore } from '@presentation/state/walletStore';
import { formatCurrency } from '@common/utils/format';
import type { RootStackParamList } from '@app/navigation/types';
import type { Balance } from '@domain/entities/Balance';
import type { ListRenderItemInfo } from 'react-native';
import { WalletManagerSheet } from '@presentation/components/WalletManagerSheet';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export function HomeScreen(): React.JSX.Element {
  const navigation =
    useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const activeWallet = useWalletStore(state => state.activeWallet);
  const balances = useWalletStore(state => state.balances);
  const portfolioValue = useWalletStore(state => state.portfolioValue);
  const change24h = useWalletStore(state => state.change24h);
  const refreshBalances = useWalletStore(state => state.refreshBalances);
  const loadingBalances = useWalletStore(state => state.loadingBalances);
  const wallets = useWalletStore(state => state.wallets);
  const selectWallet = useWalletStore(state => state.selectWallet);
  const deleteWallet = useWalletStore(state => state.deleteWallet);
  const clearWallets = useWalletStore(state => state.clearWallets);
  const [managerVisible, setManagerVisible] = useState(false);
  const insets = useSafeAreaInsets();

  useFocusEffect(
    useCallback(() => {
      refreshBalances();
    }, [refreshBalances]),
  );

  const handleOpenManager = useCallback(() => setManagerVisible(true), []);
  const handleCloseManager = useCallback(() => setManagerVisible(false), []);
  const handleDeleteWallet = useCallback(
    async (walletId: string) => {
      try {
        await deleteWallet(walletId);
      } catch (error) {
        const message =
          error instanceof Error ? error.message : 'Unable to delete wallet.';
        if (message === 'LAST_WALLET_DELETE_NOT_ALLOWED') {
          Alert.alert(
            'Cannot delete wallet',
            '至少保留一个钱包才能继续使用当前账户。',
          );
        } else {
          Alert.alert('Delete wallet failed', message);
        }
      }
    },
    [deleteWallet],
  );

  const headerComponent = useMemo(() => {
    if (!activeWallet) {
      return null;
    }
    return (
      <View>
        <TouchableOpacity activeOpacity={0.9} onPress={handleOpenManager}>
          <View style={styles.headerCard}>
            <View style={styles.headerTopRow}>
              <View>
                <Text style={styles.caption}>Total Balance</Text>
                <Text style={styles.balance}>{portfolioValue}</Text>
              </View>
              <View style={styles.changeBadge}>
                <Feather
                  name={
                    change24h.startsWith('-') ? 'arrow-down-right' : 'arrow-up-right'
                  }
                  size={16}
                  color="#10b981"
                />
                <Text style={styles.changeText}>{change24h}</Text>
              </View>
            </View>

            <View style={styles.walletRow}>
              <View style={styles.walletInfo}>
                <Text style={styles.caption}>Wallet</Text>
                <Text style={styles.addressFull}>{activeWallet.address}</Text>
                <Text style={styles.networkLabel}>{activeWallet.network.name}</Text>
              </View>
              <TouchableOpacity
                style={styles.copyButton}
                onPress={() => Clipboard.setString(activeWallet.address)}>
                <Feather name="copy" size={16} color="#f9fafb" />
              </TouchableOpacity>
            </View>

            <View style={styles.actionRow}>
              <TouchableOpacity
                style={[styles.actionButton, styles.primaryAction, styles.actionButtonLeft]}
                onPress={() => navigation.navigate('SelectToken', { returnTo: 'Send' })}>
                <Feather name="arrow-up-right" size={18} color="#f9fafb" />
                <Text style={styles.actionText}>Send</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.actionButton, styles.secondaryAction, styles.actionButtonRight]}
                onPress={() => navigation.navigate('Receive')}>
                <Feather name="arrow-down-left" size={18} color="#111827" />
                <Text style={[styles.actionText, styles.secondaryText]}>Receive</Text>
              </TouchableOpacity>
            </View>
          </View>
        </TouchableOpacity>
        <Text style={styles.assetsTitle}>Assets</Text>
      </View>
    );
  }, [activeWallet, change24h, navigation, portfolioValue, handleOpenManager]);

  const renderItem = useCallback(
    ({ item }: ListRenderItemInfo<Balance>) => (
      <View style={styles.assetRow}>
        <View>
          <Text style={styles.assetSymbol}>{item.currency.symbol}</Text>
          <Text style={styles.assetName}>{item.currency.name}</Text>
        </View>
        <View style={styles.assetValues}>
          <Text style={styles.assetAmount}>{item.amount}</Text>
          <Text style={styles.assetUsd}>{formatCurrency(item.usdValue)}</Text>
        </View>
      </View>
    ),
    [],
  );

  const renderEmpty = useCallback(
    () => (
      <View style={styles.emptyBalances}>
        {loadingBalances ? (
          <ActivityIndicator color="#6366f1" />
        ) : (
          <Text style={styles.emptyBalanceText}>No assets yet</Text>
        )}
      </View>
    ),
    [loadingBalances],
  );

  if (!activeWallet) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyTitle}>No wallet found</Text>
        <Text style={styles.emptySubtitle}>
          Create or import a wallet from the Settings tab to begin.
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={balances}
        keyExtractor={item => `${item.currency.symbol}-${item.currency.contractAddress ?? 'native'}`}
        ListHeaderComponent={headerComponent}
        renderItem={renderItem}
        refreshControl={
          <RefreshControl
            refreshing={loadingBalances}
            onRefresh={refreshBalances}
            tintColor="#6366f1"
            title={loadingBalances ? 'Refreshing…' : undefined}
            titleColor="#9ca3af"
            progressViewOffset={insets.top + 16}
          />
        }
        ListEmptyComponent={renderEmpty}
        contentContainerStyle={[
          styles.listContent,
          { paddingTop: insets.top + 24 },
        ]}
      />
      <WalletManagerSheet
        visible={managerVisible}
        wallets={wallets}
        activeWalletId={activeWallet ? activeWallet.id : null}
        onSelect={walletId => {
          selectWallet(walletId);
          handleCloseManager();
        }}
        onDelete={handleDeleteWallet}
        onImport={() => {
          handleCloseManager();
          navigation.navigate('Onboarding');
        }}
        onClearAll={() => {
          clearWallets();
          handleCloseManager();
          navigation.navigate('Onboarding');
        }}
        onClose={handleCloseManager}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#05070f',
  },
  listContent: {
    padding: 24,
    paddingBottom: 32,
  },
  headerCard: {
    backgroundColor: '#111827',
    borderRadius: 24,
    padding: 20,
    marginBottom: 24,
    shadowColor: '#000',
    shadowOpacity: 0.25,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 8 },
    elevation: 6,
  },
  headerTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  caption: {
    color: '#9ca3af',
    fontSize: 14,
  },
  balance: {
    color: '#f9fafb',
    fontSize: 32,
    fontWeight: '700',
    marginTop: 4,
  },
  changeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
  },
  changeText: {
    color: '#10b981',
    fontWeight: '600',
    marginLeft: 6,
  },
  walletRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 20,
    gap: 12,
  },
  walletInfo: {
    flex: 1,
  },
  addressFull: {
    color: '#f9fafb',
    fontSize: 14,
    fontFamily: 'Menlo',
    letterSpacing: 0.4,
    marginTop: 4,
  },
  networkLabel: {
    color: '#818cf8',
    marginTop: 4,
    fontSize: 14,
  },
  copyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1f2937',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 12,
  },
  assetsTitle: {
    color: '#f9fafb',
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 16,
  },
  actionRow: {
    flexDirection: 'row',
    marginTop: 24,
    alignItems: 'stretch',
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 14,
    borderRadius: 16,
  },
  actionButtonLeft: {
    marginRight: 8,
  },
  actionButtonRight: {
    marginLeft: 8,
  },
  primaryAction: {
    backgroundColor: '#6366f1',
  },
  secondaryAction: {
    backgroundColor: '#f9fafb',
  },
  actionText: {
    marginLeft: 8,
    fontWeight: '600',
    color: '#f9fafb',
  },
  secondaryText: {
    color: '#111827',
  },
  assetRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 18,
    borderBottomWidth: 1,
    borderBottomColor: '#1f2937',
  },
  assetSymbol: {
    color: '#f9fafb',
    fontSize: 18,
    fontWeight: '600',
  },
  assetName: {
    color: '#9ca3af',
    fontSize: 14,
    marginTop: 4,
  },
  assetValues: {
    alignItems: 'flex-end',
  },
  assetAmount: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  assetUsd: {
    color: '#9ca3af',
    marginTop: 4,
  },
  emptyBalances: {
    paddingVertical: 48,
    alignItems: 'center',
  },
  emptyBalanceText: {
    color: '#9ca3af',
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
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
});
