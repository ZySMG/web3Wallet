import { createHttpClient } from './httpClient';

export class EtherscanClient {
  private readonly chainId?: string;
  private readonly enableLogging: boolean;

  constructor(
    private readonly apiKey: string,
    {
      baseURL,
      chainId,
      enableLogging,
    }: {
      baseURL: string;
      chainId?: string;
      enableLogging?: boolean;
    },
  ) {
    this.chainId = chainId;
    this.enableLogging =
      enableLogging ??
      (typeof __DEV__ !== 'undefined'
        ? __DEV__
        : process.env.NODE_ENV !== 'production');
    this.client = createHttpClient(baseURL, apiKey);
  }

  private readonly client;

  async getEthBalance(address: string): Promise<string> {
    const config = {
      params: {
        module: 'account',
        action: 'balance',
        address,
        tag: 'latest',
      },
    };
    if (this.chainId) {
      config.params.chainid = this.chainId;
    }
    const response = await this.client.get('', config);
    return this.extractResult(response.data, 'balance');
  }

  async getTokenBalance(address: string, contractAddress: string): Promise<string> {
    const config = {
      params: {
        module: 'account',
        action: 'tokenbalance',
        address,
        contractaddress: contractAddress,
      },
    };
    if (this.chainId) {
      config.params.chainid = this.chainId;
    }
    const response = await this.client.get('', config);
    return this.extractResult(response.data, 'tokenbalance');
  }

  async getTransactions(address: string, limit = 10): Promise<any[]> {
    const config = {
      params: {
        module: 'account',
        action: 'txlist',
        address,
        startblock: 0,
        endblock: 99999999,
        page: 1,
        offset: limit,
        sort: 'desc',
      },
    };
    if (this.chainId) {
      config.params.chainid = this.chainId;
    }
    const response = await this.client.get('', config);
    return this.extractArray(response.data, 'txlist');
  }

  async getTokenTransfers(address: string, limit = 10): Promise<any[]> {
    const config = {
      params: {
        module: 'account',
        action: 'tokentx',
        address,
        startblock: 0,
        endblock: 99999999,
        page: 1,
        offset: limit,
        sort: 'desc',
      },
    };
    if (this.chainId) {
      config.params.chainid = this.chainId;
    }
    const response = await this.client.get('', config);
    return this.extractArray(response.data, 'tokentx');
  }

  private extractResult(response: any, context: string): string {
    this.logResponse(context, response);
    if (response?.status === '1') {
      return response.result as string;
    }
    this.logWarning(context, response);
    return '0';
  }

  private extractArray(response: any, context: string): any[] {
    this.logResponse(context, response);
    if (response?.status === '1' && Array.isArray(response.result)) {
      return response.result;
    }
    this.logWarning(context, response);
    return [];
  }

  private logResponse(context: string, response: any) {
    if (!this.enableLogging) {
      return;
    }
    console.log('[EtherscanClient]', context, 'response', {
      status: response?.status,
      message: response?.message,
      resultType: typeof response?.result,
      resultPreview: Array.isArray(response?.result)
        ? response.result.slice(0, 2)
        : response?.result,
    });
  }

  private logWarning(context: string, response: any) {
    if (!this.enableLogging) {
      return;
    }
    console.warn('[EtherscanClient]', context, 'returned empty result', {
      status: response?.status,
      message: response?.message,
      result: response?.result,
    });
  }
}
