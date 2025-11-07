const path = require('path');

module.exports = {
  dependencies: {
    'react-native-worklets': {
      platforms: {
        ios: {
          podspecPath: path.resolve(__dirname, 'node_modules/react-native-worklets/RNWorklets.podspec'),
        },
      },
    },
  },
};
