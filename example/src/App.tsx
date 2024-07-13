import { useRef, useEffect } from 'react';
import { StyleSheet, View, Text } from 'react-native';
import { initialize, playAudioData } from 'react-native-realtime-audio-player';

export default function App() {
  const audioOutputWs = useRef<WebSocket | null>(null);

  const handleAudioOutput = async (event: any) => {
    playAudioData(event.data);
  };

  // let's configure the web socket
  useEffect(() => {
    initialize(8192, 24000, 1);

    audioOutputWs.current = new WebSocket(`ws://your_web_socket`);
    audioOutputWs.current.onopen = () => console.log('Audio output ws open');
    audioOutputWs.current.binaryType = 'arraybuffer';
    audioOutputWs.current.onmessage = handleAudioOutput;
  }, []);

  return (
    <View style={styles.container}>
      <Text>This is a sample IOS app</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
