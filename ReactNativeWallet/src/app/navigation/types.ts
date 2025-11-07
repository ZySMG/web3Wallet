import type { NavigatorScreenParams } from '@react-navigation/native';

export type RootStackParamList = {
  Onboarding: NavigatorScreenParams<OnboardingStackParamList> | undefined;
  MainTabs: NavigatorScreenParams<MainTabParamList> | undefined;
  Send: { currencySymbol?: string } | undefined;
  Receive: undefined;
  SelectToken: { returnTo?: 'Send'; selectedSymbol?: string } | undefined;
};

export type OnboardingStackParamList = {
  Welcome: undefined;
  CreateWallet: undefined;
  ImportWallet: undefined;
};

export type MainTabParamList = {
  Home: undefined;
  Activity: undefined;
  Settings: undefined;
};
