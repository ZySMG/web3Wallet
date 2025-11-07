import React from 'react';
import { StatusBar, useColorScheme } from 'react-native';
import { RootNavigator } from './navigation/RootNavigator';
import { AppProviders } from './providers/AppProviders';

export function AppContainer(): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <AppProviders>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor="transparent"
      />
      <RootNavigator />
    </AppProviders>
  );
}
