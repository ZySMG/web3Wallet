module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    [
      'module-resolver',
      {
        root: ['./src'],
        extensions: [
          '.ts',
          '.tsx',
          '.js',
          '.jsx',
          '.json',
        ],
        alias: {
          '@app': './src/app',
          '@domain': './src/domain',
          '@data': './src/data',
          '@common': './src/common',
          '@presentation': './src/presentation',
        },
      },
    ],
    'react-native-reanimated/plugin',
  ],
};
