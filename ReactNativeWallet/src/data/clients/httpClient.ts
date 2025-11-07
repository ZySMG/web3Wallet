import axios from 'axios';

export function createHttpClient(baseURL: string, apiKey?: string) {
  const instance = axios.create({
    baseURL,
    timeout: 10_000,
    headers: {
      'Content-Type': 'application/json',
    },
  });

  instance.interceptors.request.use(config => {
    if (apiKey) {
      config.params = {
        ...(config.params ?? {}),
        apikey: apiKey,
      };
    }
    return config;
  });

  return instance;
}
