import axios from 'axios';
import { ENV } from '@app/config/env';

const SYMBOL_TO_COINGECKO_ID: Record<string, string> = {
  ETH: 'ethereum',
  USDC: 'usd-coin',
  USDT: 'tether',
};

const CACHE_TTL_MS = 60_000;

type PriceCacheEntry = {
  timestamp: number;
  value: number;
};

export class PriceService {
  private readonly cache = new Map<string, PriceCacheEntry>();

  constructor(private readonly apiKey: string = ENV.COINGECKO_API_KEY) {}

  async getUsdValue(symbol: string, amount: string): Promise<number | undefined> {
    const parsedAmount = Number(amount);
    if (Number.isNaN(parsedAmount)) {
      return undefined;
    }

    const price = await this.getTokenPrice(symbol);
    if (price === undefined) {
      return undefined;
    }

    return price * parsedAmount;
  }

  private async getTokenPrice(symbol: string): Promise<number | undefined> {
    const normalized = symbol.toUpperCase();
    const cacheEntry = this.cache.get(normalized);
    const now = Date.now();
    if (cacheEntry && now - cacheEntry.timestamp < CACHE_TTL_MS) {
      return cacheEntry.value;
    }

    const id = SYMBOL_TO_COINGECKO_ID[normalized];
    if (!id) {
      return undefined;
    }

    try {
      const response = await axios.get(
        'https://api.coingecko.com/api/v3/simple/price',
        {
          params: {
            ids: id,
            vs_currencies: 'usd',
          },
          headers: this.apiKey
            ? {
                'X-Cg-Api-Key': this.apiKey,
              }
            : undefined,
        },
      );

      const value = response.data?.[id]?.usd;
      if (typeof value === 'number') {
        this.cache.set(normalized, { value, timestamp: now });
        return value;
      }
    } catch (error) {
      console.warn('[PriceService] Failed to fetch price', error);
    }

    return undefined;
  }
}
