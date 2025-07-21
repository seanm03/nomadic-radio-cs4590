// This file contains some useful helper code for 
// managing samples and sample players. You're welcome
// to use this for any of the homeworks.  NOTE that this
// code references an AudioContext instance named 'ac'
// that is expected to be declared and initialized in
// your main sketch.

// This is the function you'll likely use the most.
// It creates and returns a new SamplePlayer UGen
// to playback a file residing in the Processing
// data folder. The UGen will remain alive after
// playback has ceased.
SamplePlayer getSamplePlayer(String fileName) {
  return getSamplePlayer(fileName, false);
}

// Returns an individual Sample, based on a WAV file
// residing in the Processing data folder
Sample getSample(String fileName) {
 return SampleManager.sample(dataPath(fileName)); 
}

// Creates a new SamplePlayer UGen. fileName is the
// name of a WAV file residing in the Processing data
// folder, and killOnEnd indicates whether the UGen
// should be killed once playback has completed.
SamplePlayer getSamplePlayer(String fileName, Boolean killOnEnd) {
  SamplePlayer player = null;
  try {
    player = new SamplePlayer(ac, getSample(fileName));
    player.setKillOnEnd(killOnEnd);
    player.setName(fileName);
  }
  catch(Exception e) {
    println("Exception while attempting to load sample: " + fileName);
    e.printStackTrace();
    exit();
  }
  
  return player;
}
