import { NativeModules, Platform } from 'react-native';
import { Buffer } from 'buffer';

const LINKING_ERROR =
  `The package 'react-native-realtime-audio-player' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const RealtimeAudioPlayer = NativeModules.RealtimeAudioPlayer
  ? NativeModules.RealtimeAudioPlayer
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

// export function multiply(a: number, b: number): Promise<number> {
//   return RealtimeAudioPlayer.multiply(a, b);
// }

export function initialize(
  bufferByteSize: number,
  sampleRate: number,
  channels: number
) {
  RealtimeAudioPlayer.initialize(bufferByteSize, sampleRate, channels);
}

export function playAudioData(dataChunk: ArrayBuffer): Promise<boolean> {
  const base64Data: string = Buffer.from(dataChunk).toString('base64');
  return RealtimeAudioPlayer.playAudioData(base64Data);
}
