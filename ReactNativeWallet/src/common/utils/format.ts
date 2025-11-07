export function formatCurrency(value: number | undefined, symbol = '$'): string {
  if (value === undefined || Number.isNaN(value)) {
    return 'N/A';
  }
  return `${symbol}${value.toFixed(2)}`;
}

export function shortenAddress(address: string, visible = 4): string {
  if (address.length <= visible * 2) {
    return address;
  }
  return `${address.slice(0, visible + 2)}…${address.slice(-visible)}`;
}
