import React, { useEffect, useMemo, useRef, useState } from 'react';
import { ActivityIndicator, Alert, ScrollView, StyleSheet, Text, View } from 'react-native';
import Clipboard from '@react-native-clipboard/clipboard';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { NETWORKS } from '@domain/entities/Network';
import { useWalletStore } from '@presentation/state/walletStore';
import type { OnboardingStackParamList } from '@app/navigation/types';

export function CreateWalletScreen(): React.JSX.Element {
  const navigation = useNavigation<NativeStackNavigationProp<OnboardingStackParamList>>();
  const createWallet = useWalletStore(state => state.createWallet);
  const [mnemonic, setMnemonic] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | undefined>();
  const hasGeneratedRef = useRef(false);

  useEffect(() => {
    if (hasGeneratedRef.current) {
      return;
    }
    hasGeneratedRef.current = true;
    setLoading(true);
    createWallet({ network: NETWORKS.sepolia })
      .then(result => {
        const phrase = result.mnemonic.trim().split(/\s+/);
        setMnemonic(phrase);
      })
      .catch(err => {
        setError(err.message ?? 'Failed to generate wallet');
      })
      .finally(() => setLoading(false));
  }, [createWallet]);

  const chunks = useMemo(() => {
    const chunked: string[][] = [];
    for (let i = 0; i < mnemonic.length; i += 3) {
      chunked.push(mnemonic.slice(i, i + 3));
    }
    return chunked;
  }, [mnemonic]);

  const handleCopy = () => {
    Clipboard.setString(mnemonic.join(' '));
    Alert.alert('Copied', 'Mnemonic copied to clipboard. Store it securely.');
  };

  const handleContinue = () => {
    const parent = navigation.getParent();
    parent?.reset({ index: 0, routes: [{ name: 'MainTabs' }] });
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#6366f1" />
        <Text style={styles.loadingText}>Generating secure wallet…</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity
          style={[styles.button, styles.primaryButton]}
          onPress={() => {
            hasGeneratedRef.current = false;
            setError(undefined);
            setMnemonic([]);
          }}>
          <Text style={styles.buttonText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Backup Your Mnemonic</Text>
      <Text style={styles.subtitle}>
        Write down these 12 words in order and store them in a safe place. This mnemonic controls your wallet.
      </Text>

      <View style={styles.mnemonicGrid}>
        {chunks.map((chunk, rowIndex) => (
          <View key={`row-${rowIndex}`} style={styles.mnemonicRow}>
            {chunk.map((word, idx) => {
              const number = rowIndex * 3 + idx + 1;
              return (
                <View key={word + number} style={styles.mnemonicCell}>
                  <Text style={styles.mnemonicIndex}>{number}.</Text>
                  <Text style={styles.mnemonicWord}>{word}</Text>
                </View>
              );
            })}
          </View>
        ))}
      </View>

      <TouchableOpacity style={[styles.button, styles.primaryButton]} onPress={handleCopy}>
        <Text style={styles.buttonText}>Copy Mnemonic</Text>
      </TouchableOpacity>

      <TouchableOpacity style={[styles.button, styles.secondaryButton]} onPress={handleContinue}>
        <Text style={styles.buttonText}>I have stored it safely</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    padding: 24,
    backgroundColor: '#05070f',
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#f9fafb',
    marginBottom: 12,
  },
  subtitle: {
    fontSize: 16,
    color: '#9ca3af',
    marginBottom: 24,
  },
  mnemonicGrid: {
    borderWidth: 1,
    borderColor: '#1f2937',
    borderRadius: 16,
    padding: 16,
    marginBottom: 24,
  },
  mnemonicRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  mnemonicCell: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#111827',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 12,
    flex: 1,
    marginHorizontal: 4,
  },
  mnemonicIndex: {
    color: '#6b7280',
    marginRight: 6,
    fontWeight: '600',
  },
  mnemonicWord: {
    color: '#f9fafb',
    fontWeight: '600',
  },
  button: {
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 16,
  },
  primaryButton: {
    backgroundColor: '#6366f1',
  },
  secondaryButton: {
    backgroundColor: '#1f2937',
  },
  buttonText: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#05070f',
    padding: 24,
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#e5e7eb',
  },
  errorText: {
    fontSize: 16,
    color: '#f87171',
    marginBottom: 16,
    textAlign: 'center',
  },
});
