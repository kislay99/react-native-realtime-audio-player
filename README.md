# react-native-realtime-audio-player

This is a package which will help you play PCM stream 

## Installation

```sh
npm install react-native-realtime-audio-player
```

## Usage


```js
import { initialize, playAudioData } from 'react-native-realtime-audio-player';

// ...
initialize(BYTE_SIZE, SAMPLE_RATE, CHANNELS);
const result = await playAudioData(event.data);
```


## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
