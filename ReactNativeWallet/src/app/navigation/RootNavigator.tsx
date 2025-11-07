import React, { useEffect } from 'react';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import {
  createNativeStackNavigator,
  type NativeStackNavigationOptions,
} from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import type { BottomTabNavigationOptions } from '@react-navigation/bottom-tabs';
import Feather from 'react-native-vector-icons/Feather';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import type {
  RootStackParamList,
  OnboardingStackParamList,
  MainTabParamList,
} from './types';
import { HomeScreen } from '@presentation/screens/home/HomeScreen';
import { ActivityScreen } from '@presentation/screens/activity/ActivityScreen';
import { SettingsScreen } from '@presentation/screens/settings/SettingsScreen';
import { WelcomeScreen } from '@presentation/screens/onboarding/WelcomeScreen';
import { CreateWalletScreen } from '@presentation/screens/onboarding/CreateWalletScreen';
import { ImportWalletScreen } from '@presentation/screens/onboarding/ImportWalletScreen';
import { SendScreen } from '@presentation/screens/send/SendScreen';
import { ReceiveScreen } from '@presentation/screens/receive/ReceiveScreen';
import { SelectTokenScreen } from '@presentation/screens/send/SelectTokenScreen';
import { useWalletStore } from '@presentation/state/walletStore';

const RootStack = createNativeStackNavigator<RootStackParamList>();
const OnboardingStack = createNativeStackNavigator<OnboardingStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

const sharedTabOptions: BottomTabNavigationOptions = {
  headerShown: false,
  tabBarActiveTintColor: '#6366f1',
  tabBarInactiveTintColor: '#6b7280',
  tabBarStyle: {
    backgroundColor: '#0b1120',
    borderTopWidth: 0,
    paddingVertical: 10,
    height: 72,
  },
};

const homeTabOptions: BottomTabNavigationOptions = {
  tabBarIcon: ({ color, size }) => (
    <Feather name="home" color={color} size={size} />
  ),
};

const activityTabOptions: BottomTabNavigationOptions = {
  tabBarIcon: ({ color, size }) => (
    <Feather name="clock" color={color} size={size} />
  ),
};

const settingsTabOptions: BottomTabNavigationOptions = {
  tabBarIcon: ({ color, size }) => (
    <Feather name="settings" color={color} size={size} />
  ),
};

const darkTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: '#05070f',
    card: '#0b1120',
    text: '#f9fafb',
    border: '#111827',
  },
};

function OnboardingNavigator(): React.JSX.Element {
  return (
    <OnboardingStack.Navigator
      screenOptions={{ headerShown: false, animation: 'slide_from_right' }}>
      <OnboardingStack.Screen name="Welcome" component={WelcomeScreen} />
      <OnboardingStack.Screen
        name="CreateWallet"
        component={CreateWalletScreen}
      />
      <OnboardingStack.Screen
        name="ImportWallet"
        component={ImportWalletScreen}
      />
    </OnboardingStack.Navigator>
  );
}

function MainTabs(): React.JSX.Element {
  return (
    <Tab.Navigator screenOptions={sharedTabOptions}>
      <Tab.Screen name="Home" component={HomeScreen} options={homeTabOptions} />
      <Tab.Screen
        name="Activity"
        component={ActivityScreen}
        options={activityTabOptions}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsScreen}
        options={settingsTabOptions}
      />
    </Tab.Navigator>
  );
}

export function RootNavigator(): React.JSX.Element {
  const initialize = useWalletStore(state => state.initialize);
  const isInitializing = useWalletStore(state => state.isInitializing);
  const wallets = useWalletStore(state => state.wallets);
  const activeWallet = useWalletStore(state => state.activeWallet);

  useEffect(() => {
    initialize();
  }, [initialize]);

  const hasWallet = wallets.length > 0 && activeWallet !== null;
  const containerKey = hasWallet ? 'main-flow' : 'onboarding-flow';

  if (isInitializing) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#6366f1" />
      </View>
    );
  }

  return (
    <NavigationContainer theme={darkTheme} key={containerKey}>
      <RootStack.Navigator
        key={hasWallet ? 'main' : 'onboarding'}
        initialRouteName={hasWallet ? 'MainTabs' : 'Onboarding'}
        screenOptions={{ headerShown: false }}>
        <RootStack.Screen name="MainTabs" component={MainTabs} />
        <RootStack.Screen name="Onboarding" component={OnboardingNavigator} />
        <RootStack.Screen
          name="Send"
          component={SendScreen}
          options={sendReceiveOptions('Send Tokens')}
        />
        <RootStack.Screen
          name="SelectToken"
          component={SelectTokenScreen}
          options={sendReceiveOptions('Select Token')}
        />
        <RootStack.Screen
          name="Receive"
          component={ReceiveScreen}
          options={sendReceiveOptions('Receive Tokens')}
        />
      </RootStack.Navigator>
    </NavigationContainer>
  );
}

function sendReceiveOptions(title: string): NativeStackNavigationOptions {
  return {
    headerShown: true,
    headerTitle: title,
    headerTintColor: '#f9fafb',
    headerStyle: {
      backgroundColor: '#0b1120',
    },
    contentStyle: {
      backgroundColor: '#05070f',
    },
  };
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#05070f',
  },
});
