import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { OnboardingStackParamList } from '@app/navigation/types';
import { TouchableOpacity } from 'react-native-gesture-handler';

export function WelcomeScreen(): React.JSX.Element {
  const navigation = useNavigation<NativeStackNavigationProp<OnboardingStackParamList>>();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome to Web3 Wallet</Text>
      <Text style={styles.subtitle}>
        Manage your Ethereum assets on Sepolia testnet. Create a new wallet or import an
        existing one to get started.
      </Text>

      <TouchableOpacity
        style={[styles.button, styles.primaryButton]}
        onPress={() => navigation.navigate('CreateWallet')}>
        <Text style={styles.buttonText}>Create New Wallet</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, styles.secondaryButton]}
        onPress={() => navigation.navigate('ImportWallet')}>
        <Text style={styles.buttonText}>Import with Mnemonic</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 24,
    justifyContent: 'center',
    backgroundColor: '#05070f',
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
    color: '#f9fafb',
    marginBottom: 16,
  },
  subtitle: {
    fontSize: 16,
    color: '#9ca3af',
    marginBottom: 32,
  },
  button: {
    paddingVertical: 16,
    borderRadius: 12,
    marginBottom: 16,
    alignItems: 'center',
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
});
