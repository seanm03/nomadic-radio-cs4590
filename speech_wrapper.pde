//
// This code is a simple wrapper around the FreeTTS library to make it a bit easier to work with.
// To use it:
//    1. Instantiate a single instance of SpeechWrapper inside your setup() method.
//    2. Call textToSpeechAudio() if you simply want the TTS system to play your text
//       immediately through the speaker; note that this completely bypasses Beads and
//       any UGens you may have created, and you won't get a notification when the speech
//       has finished playing.  But it'll work well enough for some cases. Be aware that
//       this method blocks until the speech clip has finished rendering.
//    3. Call textToSpeechWaveFile() to have the TTS system render your speech clip into
//       a Wave file. Note that the code here will create a folder called tts_samples
//       inside your sketch's data directory to hold these. This method returns the full
//       path to the generated Wave file, so that if you wish, you can set up a SamplePlayer
//       to render it from inside your Beads UGen graph. See the calling code for an 
//       example of how to do this.
//
// This file is based on code from Maribeth Gandy and Scott Robertson, modified by Keith Edwards
//
import com.sun.speech.freetts.FreeTTS;
import com.sun.speech.freetts.Voice;
import com.sun.speech.freetts.VoiceManager;
import com.sun.speech.freetts.Gender;
import com.sun.speech.freetts.audio.AudioPlayer;
import com.sun.speech.freetts.audio.SingleFileAudioPlayer;
import javax.sound.sampled.AudioFileFormat.Type;


class SpeechWrapper {
  private Voice voice;

  private final String TTS_FILE_DIRECTORY_NAME = "tts_samples";
  private final String TTS_FILE_PREFIX = "tts";

  private File ttsDir;
  private boolean isSetup = false;
  private int fileID = 0;

  public SpeechWrapper() {
    // On Processing 4.x and later we need to set this system property before loading any voices,
    // otherwise the default loading mechanism raises an error.
    System.setProperty("freetts.voices", "com.sun.speech.freetts.en.us.cmu_us_kal.KevinVoiceDirectory");
    VoiceManager voiceManager = VoiceManager.getInstance();
    // Kevin is the only voice supported
    voice = voiceManager.getVoice("kevin16");
    
    // Find our samples directory and clean it out if it has files from a previous run of this sketch
    findTTSDirectory();
    cleanTTSDirectory();

    voice.allocate();
  }

  String getTTSFilePath() {
    return dataPath(TTS_FILE_DIRECTORY_NAME);
  }

  // Finds the TTS directory under the data path and creates it if it doesn't exist
  void findTTSDirectory() {
    File dataDir = new File(dataPath(""));
    println("Data Dir is " + dataDir);
    if (!dataDir.exists()) {
      try {
        dataDir.mkdir();
      } catch(Exception ex) {
        println("Data directory not present, and could not be automatically created: " + ex.getMessage());
        ex.printStackTrace();
      }
    }

    ttsDir = new File(getTTSFilePath());
    println("TTS directory is " + ttsDir);
    boolean directoryExists = ttsDir.exists();
    if (!directoryExists) {
      try {
        ttsDir.mkdir();
        directoryExists = true;
      } catch(Exception ex) {
        println("Error creating tts file directory '" + TTS_FILE_DIRECTORY_NAME + "' in the data directory: " +
          ex.getMessage());
        ex.printStackTrace();
      }
    }
  }

  // deletes ALL files in the TTS file drectory
  void cleanTTSDirectory() {
    println("Cleaning TTS directory: " + ttsDir);
    if (ttsDir.exists()) {
      println("It exists");
      for (File file : ttsDir.listFiles()) {
        println("Deleting " + file);
        if (!file.isDirectory()) {
          file.delete();
        }
      }
    }
  }

  // Create a WAV file of the input speech and return the path to that file, relative to the data
  // directory for the sketch.  You'll have to pass this value to dataPath() if you ever need
  // a full path to it.
  public String textToSpeechWaveFile(String s) {
    String path = TTS_FILE_DIRECTORY_NAME + "/" + TTS_FILE_PREFIX + Integer.toString(fileID);
    fileID++;
    // To render the speech to a wave file we swap out the voice's current audio player 
    // with a SingleFileAudio player set up to write to the file, then swap it back
    // when we're done.
    AudioPlayer oldPlayer = voice.getAudioPlayer();
    SingleFileAudioPlayer newPlayer = new SingleFileAudioPlayer(dataPath(path), Type.WAVE);
    voice.setAudioPlayer(newPlayer);
    voice.speak(s);
    newPlayer.close();
    voice.setAudioPlayer(oldPlayer);
    // You will need to use dataPath(filePath) if you need the full path to this file.
    // SingleFileAudioPlayer automatically appends ".wav" to the filename, so we need to add it here
    return path + ".wav";
  }

  // textToSpeechAudio() just causes the speech synthesizer to output whatever string is given to it;
  // it's not connected to any Beads UGen, so it's "outside" the entire Beads processing chain.
  // Note that this method blocks, so be aware that caling it from a button may do things like
  // block the event handling thread.
  public void textToSpeechAudio(String s) {
    voice.speak(s);
  }
  
  // Nonblocking version of textToSpeechAudio. Note that this may cause currently playing
  // audio clips to be interrupted or mixed with the new clip.
  public void textToSpeechAudioNonblocking(String s) {
    Runnable speaker = new Runnable() {
      public void run() {
        voice.speak(s);
      }
    };
    (new Thread(speaker)).start();
  }
  
  // Below are some simple methods to tweak a few voice parameters. These are included here so 
  // that your code can use them without having to import all the com.sun.speech stuff.

  // Sets the "baseline" pitch of the voice, in hertz. Default is 100.0
  public void setPitch(float pitch) {
    voice.setPitch(pitch);
  }

  // Shift the overall pitch of the voice by some amount (1.0 is no shift, and is the default)
  public void setPitchShift(float p) {
    voice.setPitchShift(p);
  }

  // Sets the range of the voice's pitch, in hertz. Default is 11.0
  public void setPitchRange(float p) {
    voice.setPitchRange(p);
  }

  // Change the rate of speaking to a new words-per-minute. Default is 150.
  public void setRate(float wpm) {
    System.out.println("Old rate: " + voice.getRate());
    voice.setRate(wpm);
  }

  // Set the volume (0.0 - 1.0). Default is 1.0
  public void setVolume(float v) {
    voice.setVolume(v);
  }
}
