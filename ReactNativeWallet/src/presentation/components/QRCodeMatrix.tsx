import React, { useMemo } from 'react';
import { View, StyleSheet } from 'react-native';
import QRCode from 'qrcode';

type QRCodeMatrixProps = {
  value: string;
  size: number;
  color?: string;
  backgroundColor?: string;
  errorCorrectionLevel?: 'L' | 'M' | 'Q' | 'H';
};

/**
 * Lightweight QR code renderer that does not rely on react-native-svg.
 * Generates a boolean matrix using the `qrcode` JS library and renders it using View blocks.
 */
export function QRCodeMatrix({
  value,
  size,
  color = '#000000',
  backgroundColor = '#ffffff',
  errorCorrectionLevel = 'M',
}: QRCodeMatrixProps): React.JSX.Element {
  const matrix = useMemo(() => {
    const qr = QRCode.create(value, { errorCorrectionLevel });
    const data = qr.modules.data as boolean[];
    const dimension = qr.modules.size;

    const rows: boolean[][] = [];
    for (let i = 0; i < dimension; i += 1) {
      const row: boolean[] = [];
      for (let j = 0; j < dimension; j += 1) {
        row.push(Boolean(data[i * dimension + j]));
      }
      rows.push(row);
    }

    return rows;
  }, [value, errorCorrectionLevel]);

  const cellSize = size / matrix.length;

  return (
    <View
      style={[
        styles.container,
        {
          width: size,
          height: size,
          backgroundColor,
        },
      ]}>
      {matrix.map((row, rowIndex) => (
        <View key={`row-${rowIndex}`} style={styles.row}>
          {row.map((filled, colIndex) => (
            <View
              key={`cell-${rowIndex}-${colIndex}`}
              style={{
                width: cellSize,
                height: cellSize,
                backgroundColor: filled ? color : backgroundColor,
              }}
            />
          ))}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  row: {
    flexDirection: 'row',
  },
});
