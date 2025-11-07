import React, { useMemo } from 'react';
import {
  Modal,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  ScrollView,
} from 'react-native';
import type { Wallet } from '@domain/entities/Wallet';
import { shortenAddress } from '@common/utils/format';

type WalletManagerSheetProps = {
  visible: boolean;
  wallets: Wallet[];
  activeWalletId: string | null;
  onSelect: (walletId: string) => void;
  onDelete: (walletId: string) => void;
  onImport: () => void;
  onClearAll: () => void;
  onClose: () => void;
};

export function WalletManagerSheet({
  visible,
  wallets,
  activeWalletId,
  onSelect,
  onDelete,
  onImport,
  onClearAll,
  onClose,
}: WalletManagerSheetProps): React.JSX.Element {
  const grouped = useMemo(() => {
    const generated = wallets.filter(wallet => !wallet.isImported);
    const imported = wallets.filter(wallet => wallet.isImported);
    return { generated, imported };
  }, [wallets]);

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      onRequestClose={onClose}>
      <View style={styles.backdrop}>
        <TouchableOpacity style={StyleSheet.absoluteFill} onPress={onClose} />
        <View style={styles.sheet}>
          <View style={styles.header}>
            <Text style={styles.title}>Wallet Management</Text>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Text style={styles.closeText}>×</Text>
            </TouchableOpacity>
          </View>

          <ScrollView contentContainerStyle={styles.content}>
            {grouped.generated.length > 0 && (
              <WalletSection
                title="Generated Wallets"
                wallets={grouped.generated}
                activeWalletId={activeWalletId}
                onSelect={onSelect}
                onDelete={onDelete}
              />
            )}

            {grouped.imported.length > 0 && (
              <WalletSection
                title="Imported Wallets"
                wallets={grouped.imported}
                activeWalletId={activeWalletId}
                onSelect={onSelect}
                onDelete={onDelete}
              />
            )}

            {wallets.length === 0 && (
              <View style={styles.empty}>
                <Text style={styles.emptyText}>No wallets yet.</Text>
              </View>
            )}
          </ScrollView>

          <View style={styles.footer}>
            <TouchableOpacity style={styles.primaryButton} onPress={onImport}>
              <Text style={styles.primaryButtonText}>Import Wallet</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.dangerButton} onPress={onClearAll}>
              <Text style={styles.dangerButtonText}>Clear All Wallets</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

type WalletSectionProps = {
  title: string;
  wallets: Wallet[];
  activeWalletId: string | null;
  onSelect: (walletId: string) => void;
  onDelete: (walletId: string) => void;
};

function WalletSection({
  title,
  wallets,
  activeWalletId,
  onSelect,
  onDelete,
}: WalletSectionProps) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {wallets.map(wallet => {
        const isActive = wallet.id === activeWalletId;
        return (
          <View key={wallet.id} style={styles.walletRow}>
            <TouchableOpacity
              style={styles.walletInfo}
              onPress={() => onSelect(wallet.id)}>
              <Text style={styles.walletName}>
                {wallet.name || (wallet.isImported ? 'Imported Wallet' : 'Generated Wallet')}
              </Text>
              <Text style={styles.walletAddress}>{shortenAddress(wallet.address, 6)}</Text>
            </TouchableOpacity>
            {isActive && <Text style={styles.activeBadge}>Active</Text>}
            <TouchableOpacity
              onPress={() => onDelete(wallet.id)}
              style={styles.deleteButton}>
              <Text style={styles.deleteText}>Delete</Text>
            </TouchableOpacity>
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(5, 7, 15, 0.6)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: '#101327',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 32,
    maxHeight: '80%',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  title: {
    color: '#f9fafb',
    fontSize: 18,
    fontWeight: '700',
  },
  closeButton: {
    position: 'absolute',
    right: 0,
    top: -4,
    padding: 8,
  },
  closeText: {
    fontSize: 24,
    color: '#9ca3af',
  },
  content: {
    paddingBottom: 16,
  },
  section: {
    marginBottom: 16,
  },
  sectionTitle: {
    color: '#9ca3af',
    fontSize: 14,
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  walletRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#1f2937',
  },
  walletInfo: {
    flex: 1,
  },
  walletName: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  walletAddress: {
    color: '#9ca3af',
    fontSize: 13,
    marginTop: 4,
  },
  activeBadge: {
    color: '#34d399',
    fontWeight: '600',
    marginRight: 12,
  },
  deleteButton: {
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  deleteText: {
    color: '#f87171',
    fontWeight: '600',
  },
  footer: {
    gap: 12,
  },
  primaryButton: {
    backgroundColor: '#3b82f6',
    paddingVertical: 14,
    borderRadius: 16,
    alignItems: 'center',
  },
  primaryButtonText: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  dangerButton: {
    backgroundColor: '#ef4444',
    paddingVertical: 14,
    borderRadius: 16,
    alignItems: 'center',
  },
  dangerButtonText: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  empty: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  emptyText: {
    color: '#6b7280',
  },
});
