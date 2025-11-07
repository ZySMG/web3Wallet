import React from 'react';
import { Alert, StyleSheet, Text, View } from 'react-native';
import Clipboard from '@react-native-clipboard/clipboard';
import Feather from 'react-native-vector-icons/Feather';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { TouchableOpacity, ScrollView } from 'react-native-gesture-handler';
import { useWalletStore } from '@presentation/state/walletStore';
import type { RootStackParamList } from '@app/navigation/types';
import { shortenAddress } from '@common/utils/format';

type SettingsNavigationProp = NativeStackNavigationProp<RootStackParamList>;

export function SettingsScreen(): React.JSX.Element {
  const navigation = useNavigation<SettingsNavigationProp>();
  const { wallets, activeWallet, selectWallet } = useWalletStore(state => ({
    wallets: state.wallets,
    activeWallet: state.activeWallet,
    selectWallet: state.selectWallet,
  }));

  const handleCopy = () => {
    if (activeWallet) {
      Clipboard.setString(activeWallet.address);
      Alert.alert('Copied', 'Address copied to clipboard');
    }
  };

  const handleCreate = () => {
    navigation.navigate('Onboarding', { screen: 'CreateWallet' });
  };

  const handleImport = () => {
    navigation.navigate('Onboarding', { screen: 'ImportWallet' });
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Wallet Settings</Text>

      {activeWallet && (
        <View style={styles.card}>
          <Text style={styles.sectionLabel}>Active Wallet</Text>
          <Text style={styles.walletName}>{activeWallet.name || 'Primary Wallet'}</Text>
          <Text style={styles.walletAddress}>{shortenAddress(activeWallet.address)}</Text>
          <Text style={styles.network}>{activeWallet.network.name}</Text>

          <TouchableOpacity style={styles.copyButton} onPress={handleCopy}>
            <Feather name="copy" size={16} color="#f9fafb" />
            <Text style={styles.copyText}>Copy Address</Text>
          </TouchableOpacity>
        </View>
      )}

      <View style={styles.card}>
        <Text style={styles.sectionLabel}>Wallets</Text>
        {wallets.map(wallet => {
          const isActive = wallet.id === activeWallet?.id;
          return (
            <TouchableOpacity
              key={wallet.id}
              style={[styles.walletRow, isActive && styles.walletRowActive]}
              onPress={() => selectWallet(wallet.id)}>
              <View>
                <Text style={styles.walletRowName}>{wallet.name || 'Wallet'}</Text>
                <Text style={styles.walletRowAddress}>{shortenAddress(wallet.address)}</Text>
              </View>
              {isActive && <Feather name="check" size={18} color="#34d399" />}
            </TouchableOpacity>
          );
        })}

        <View style={styles.walletActions}>
          <TouchableOpacity style={[styles.actionButton, styles.primaryAction]} onPress={handleCreate}>
            <Feather name="plus" size={16} color="#f9fafb" />
            <Text style={styles.actionText}>Create Wallet</Text>
          </TouchableOpacity>
          <TouchableOpacity style={[styles.actionButton, styles.secondaryAction]} onPress={handleImport}>
            <Feather name="download" size={16} color="#111827" />
            <Text style={[styles.actionText, styles.secondaryText]}>Import Wallet</Text>
          </TouchableOpacity>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#05070f',
  },
  content: {
    padding: 24,
  },
  title: {
    color: '#f9fafb',
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 24,
  },
  card: {
    backgroundColor: '#111827',
    borderRadius: 24,
    padding: 20,
    marginBottom: 24,
  },
  sectionLabel: {
    color: '#9ca3af',
    fontSize: 14,
    letterSpacing: 0.4,
    textTransform: 'uppercase',
    marginBottom: 12,
  },
  walletName: {
    color: '#f9fafb',
    fontSize: 20,
    fontWeight: '700',
  },
  walletAddress: {
    color: '#9ca3af',
    marginTop: 4,
  },
  network: {
    color: '#818cf8',
    marginTop: 8,
  },
  copyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 16,
    backgroundColor: '#1f2937',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 12,
  },
  copyText: {
    color: '#f9fafb',
    marginLeft: 8,
    fontWeight: '600',
  },
  walletRow: {
    backgroundColor: '#0f172a',
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  walletRowActive: {
    borderWidth: 1,
    borderColor: '#34d399',
  },
  walletRowName: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  walletRowAddress: {
    color: '#9ca3af',
    marginTop: 4,
  },
  walletActions: {
    flexDirection: 'row',
    marginTop: 12,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 14,
    borderRadius: 16,
  },
  primaryAction: {
    backgroundColor: '#6366f1',
    marginRight: 8,
  },
  secondaryAction: {
    backgroundColor: '#f9fafb',
    marginLeft: 8,
  },
  actionText: {
    marginLeft: 8,
    fontWeight: '600',
    color: '#f9fafb',
  },
  secondaryText: {
    color: '#111827',
  },
});
