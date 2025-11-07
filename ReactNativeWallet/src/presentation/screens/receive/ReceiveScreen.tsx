import React from 'react';
import { Alert, Platform, StyleSheet, Text, View } from 'react-native';
import Clipboard from '@react-native-clipboard/clipboard';
import Feather from 'react-native-vector-icons/Feather';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { useWalletStore } from '@presentation/state/walletStore';
import { shortenAddress } from '@common/utils/format';
import { QRCodeMatrix } from '@presentation/components/QRCodeMatrix';

export function ReceiveScreen(): React.JSX.Element {
  const activeWallet = useWalletStore(state => state.activeWallet);

  if (!activeWallet) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyTitle}>No wallet selected</Text>
        <Text style={styles.emptySubtitle}>Import or create a wallet to receive funds.</Text>
      </View>
    );
  }

  const handleCopy = () => {
    Clipboard.setString(activeWallet.address);
    Alert.alert('Copied', 'Address copied to clipboard');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Receive Assets</Text>
      <Text style={styles.subtitle}>Scan to receive tokens on {activeWallet.network.name}.</Text>

      <View style={styles.qrContainer}>
        <QRCodeMatrix
          value={activeWallet.address}
          size={220}
          backgroundColor="#0b1120"
          color="#f9fafb"
        />
      </View>

      <View style={styles.addressCard}>
        <Text style={styles.addressLabel}>Your Address</Text>
        <Text style={styles.addressFull} selectable>
          {activeWallet.address}
        </Text>
        <Text style={styles.addressPreview}>{shortenAddress(activeWallet.address, 6)}</Text>
        <TouchableOpacity style={styles.copyButton} onPress={handleCopy}>
          <Feather name="copy" size={16} color="#f9fafb" />
          <Text style={styles.copyButtonText}>Copy to clipboard</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#05070f',
    padding: 24,
    alignItems: 'center',
  },
  title: {
    color: '#f9fafb',
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 12,
  },
  subtitle: {
    color: '#9ca3af',
    fontSize: 16,
    marginBottom: 24,
    textAlign: 'center',
  },
  qrContainer: {
    backgroundColor: '#0b1120',
    padding: 16,
    borderRadius: 24,
    marginBottom: 32,
  },
  addressCard: {
    backgroundColor: '#111827',
    borderRadius: 24,
    padding: 20,
    alignItems: 'center',
    width: '100%',
  },
  addressLabel: {
    color: '#9ca3af',
    fontSize: 14,
    marginBottom: 8,
  },
  addressFull: {
    color: '#f9fafb',
    fontSize: 14,
    fontFamily: Platform.select({ ios: 'Menlo', android: 'monospace', default: 'monospace' }),
    letterSpacing: 0.5,
    marginBottom: 8,
    textAlign: 'center',
  },
  addressPreview: {
    color: '#f9fafb',
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
  },
  copyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#6366f1',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 16,
  },
  copyButtonText: {
    color: '#f9fafb',
    fontWeight: '600',
    marginLeft: 8,
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
});
