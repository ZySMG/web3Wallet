import React, { useMemo } from 'react';
import {
  FlatList,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import type { RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { SUPPORTED_CURRENCIES } from '@domain/entities/Currency';
import type { RootStackParamList } from '@app/navigation/types';
import { useWalletStore } from '@presentation/state/walletStore';

type TokenItem = {
  symbol: string;
  name: string;
  balance: string;
  isImported: boolean;
};

export function SelectTokenScreen(): React.JSX.Element {
  const navigation =
    useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const route = useRoute<RouteProp<RootStackParamList, 'SelectToken'>>();
  const balances = useWalletStore(state => state.balances);
  const selectedSymbol = route.params?.selectedSymbol;
  const returnTo = route.params?.returnTo;

  const tokens = useMemo<TokenItem[]>(() => {
    return SUPPORTED_CURRENCIES.map(currency => {
      const balance = balances.find(
        entry => entry.currency.symbol === currency.symbol,
      );
      return {
        symbol: currency.symbol,
        name: currency.name,
        balance: balance?.amount ?? '0',
        isImported: Boolean(currency.contractAddress),
      };
    });
  }, [balances]);

  const handleSelect = (symbol: string) => {
    if (returnTo === 'Send') {
      navigation.replace('Send', { currencySymbol: symbol });
    } else {
      navigation.navigate('Send', { currencySymbol: symbol });
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Select Token</Text>
      <FlatList
        data={tokens}
        keyExtractor={item => item.symbol}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[
              styles.row,
              item.symbol === selectedSymbol && styles.rowSelected,
            ]}
            onPress={() => handleSelect(item.symbol)}>
            <View>
              <Text style={styles.symbol}>{item.symbol}</Text>
              <Text style={styles.name}>{item.name}</Text>
            </View>
            <View style={styles.balanceColumn}>
              <Text style={styles.balance}>{item.balance}</Text>
              <Text style={styles.balanceLabel}>Available</Text>
            </View>
          </TouchableOpacity>
        )}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        contentContainerStyle={styles.listContent}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#05070f',
    padding: 24,
  },
  title: {
    color: '#f9fafb',
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 24,
  },
  listContent: {
    paddingBottom: 24,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 16,
    paddingHorizontal: 20,
    borderRadius: 16,
    backgroundColor: '#111827',
  },
  rowSelected: {
    borderWidth: 1,
    borderColor: '#6366f1',
  },
  symbol: {
    color: '#f9fafb',
    fontSize: 18,
    fontWeight: '700',
  },
  name: {
    color: '#9ca3af',
    fontSize: 13,
    marginTop: 4,
  },
  balanceColumn: {
    alignItems: 'flex-end',
  },
  balance: {
    color: '#f9fafb',
    fontSize: 16,
    fontWeight: '600',
  },
  balanceLabel: {
    color: '#6b7280',
    fontSize: 12,
    marginTop: 4,
  },
  separator: {
    height: 12,
  },
});
