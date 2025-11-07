import React, { useCallback, useMemo, useState } from 'react';
import {
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
} from 'react-native';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { NETWORKS } from '@domain/entities/Network';
import type { OnboardingStackParamList } from '@app/navigation/types';
import { useWalletStore } from '@presentation/state/walletStore';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export function ImportWalletScreen(): React.JSX.Element {
  const navigation = useNavigation<NativeStackNavigationProp<OnboardingStackParamList>>();
  const importWallet = useWalletStore(state => state.importWallet);
  const insets = useSafeAreaInsets();
  const [mnemonic, setMnemonic] = useState('');
  const [loading, setLoading] = useState(false);

  const handleImport = useCallback(() => {
    if (loading) {
      return;
    }

    const sanitized = mnemonic.trim();
    if (sanitized.split(/\s+/).length < 12) {
      Alert.alert('Invalid mnemonic', 'Please enter a valid 12 or 24-word mnemonic phrase.');
      return;
    }
    setLoading(true);
    importWallet({ mnemonic: sanitized, network: NETWORKS.sepolia })
      .then(() => {
        const parent = navigation.getParent();
        parent?.reset({ index: 0, routes: [{ name: 'MainTabs' }] });
      })
      .catch(error => {
        const message =
          error instanceof Error && error.message
            ? error.message
            : 'Unable to import wallet';
        const resolvedMessage =
          message === 'WALLET_ALREADY_IMPORTED'
            ? 'This wallet has already been imported.'
            : message;
        Alert.alert('Import failed', resolvedMessage);
      })
      .finally(() => setLoading(false));
  }, [importWallet, loading, mnemonic, navigation]);

  const containerStyle = useMemo(
    () => [
      styles.container,
      {
        paddingTop: insets.top + 16,
      },
    ],
    [insets.top],
  );

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.select({ ios: 'padding', android: undefined })}>
      <ScrollView contentContainerStyle={containerStyle} keyboardShouldPersistTaps="handled">
        <Text style={styles.title}>Import Wallet</Text>
        <Text style={styles.subtitle}>
          Paste your existing mnemonic phrase. Ensure you are in a private environment before proceeding.
        </Text>

        <TextInput
          style={styles.textArea}
          value={mnemonic}
          onChangeText={setMnemonic}
          placeholder="enter your mnemonic here"
          placeholderTextColor="#6b7280"
          multiline
          editable={!loading}
          autoCapitalize="none"
          autoCorrect={false}
        />

        <TouchableOpacity
          style={[styles.button, styles.primaryButton, loading && styles.disabledButton]}
          onPress={handleImport}
          disabled={loading}>
          <Text style={styles.buttonText}>{loading ? 'Importing…' : 'Import Wallet'}</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
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
  textArea: {
    minHeight: 150,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#1f2937',
    padding: 16,
    color: '#f9fafb',
    backgroundColor: '#111827',
    fontSize: 16,
    textAlignVertical: 'top',
    marginBottom: 24,
  },
  button: {
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  primaryButton: {
    backgroundColor: '#6366f1',
  },
  buttonText: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  disabledButton: {
    opacity: 0.6,
  },
});
