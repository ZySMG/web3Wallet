import * as Keychain from 'react-native-keychain';

const DEFAULT_SERVICE = 'web3wallet_secret_storage';

export async function storeMnemonic(
  key: string,
  mnemonic: string,
): Promise<void> {
  await Keychain.setGenericPassword('mnemonic', mnemonic, {
    service: `${DEFAULT_SERVICE}_${key}`,
  });
}

export async function getMnemonic(key: string): Promise<string | null> {
  const credentials = await Keychain.getGenericPassword({
    service: `${DEFAULT_SERVICE}_${key}`,
  });
  if (!credentials) {
    return null;
  }
  return credentials.password;
}

export async function removeMnemonic(key: string): Promise<void> {
  await Keychain.resetGenericPassword({ service: `${DEFAULT_SERVICE}_${key}` });
}
