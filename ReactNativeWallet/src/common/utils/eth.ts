import { formatUnits, parseUnits } from 'ethers';

export function toDecimalAmount(
  rawAmount: string | bigint,
  decimals: number,
  precision = 6,
): string {
  const formatted = formatUnits(rawAmount, decimals);
  const [integer, fraction = ''] = formatted.split('.');

  if (precision === 0) {
    return integer;
  }

  const trimmedFraction = fraction.slice(0, precision).replace(/0+$/, '');
  return trimmedFraction.length > 0
    ? `${integer}.${trimmedFraction}`
    : integer;
}

export function toRawAmount(amount: string, decimals: number): bigint {
  return parseUnits(amount, decimals);
}
