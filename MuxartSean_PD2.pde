import beads.*;
import controlP5.*;

AudioContext ac;
ControlP5 p5;

NotificationServer server;
SpeechWrapper tts;
Timer timer = new Timer();

SamplePlayer bgPlayer;
Gain masterGain, notiGain, beepGain;
Glide notiGlide, beepGlide;
BiquadFilter lp;

boolean isBgPlaying = false;
HashMap<String, String> bgSounds = new HashMap<>();
WavePlayer vmBeep;
final int vmBeepLength = 600;
final float defaultNotiVol = 0.5;
final float defaultVmVol = 0.4;

boolean[] eventTypeFilters = {true, true, true, true, true};
int selContext = 0, selStream = 0;

void setup() {
  size(600, 300);

  ac = new AudioContext();
  masterGain = new Gain(ac, 3, 0.8);
  notiGlide = new Glide(ac, defaultNotiVol, 500);
  notiGain = new Gain(ac, 1, notiGlide);
  beepGlide = new Glide(ac, defaultVmVol, 400);
  beepGain = new Gain(ac, 1, beepGlide);
  lp = new BiquadFilter(ac, BiquadFilter.LP, 250.0, 0.8);
  notiGain.addInput(lp);

  server = new NotificationServer();
  tts = new SpeechWrapper();
  server.addListener(new QueuingListener());

  // ui stuff
  p5 = new ControlP5(this);
  p5.addRadioButton("Context")
    .setPosition(50, 60)
    .setSize(30, 30)
    .setItemsPerRow(1)
    .addItem("Working Out", 0)
    .addItem("Walking", 1)
    .addItem("Socializing", 2)
    .addItem("Presenting", 3);

  p5.addRadioButton("Streams")
    .setPosition(470, 60)
    .setSize(30, 30)
    .setItemsPerRow(1)
    .addItem("Stream 1", 0)
    .addItem("Stream 2", 1)
    .addItem("Stream 3", 2);

  p5.addCheckBox("EventTypes")
    .setPosition(270, 60)
    .setSize(30, 30)
    .setItemsPerRow(1)
    .addItem("Twitter", 0)
    .addItem("Email", 1)
    .addItem("Text", 2)
    .addItem("PhoneCall", 3)
    .addItem("VoiceMail", 4)
    .activateAll();

  // background sounds
  bgSounds.put("Working Out", "gym_ambience.wav");
  bgSounds.put("Walking", "walking_ambience.wav");
  bgSounds.put("Socializing", "coffee_shop.wav");
  bgSounds.put("Presenting", "presenting_ambience.wav");

  masterGain.addInput(notiGain);
  masterGain.addInput(beepGain);
  ac.out.addInput(masterGain);
  ac.start();
}

String getContextName() {
  switch (selContext) {
    case 0: return "Working Out";
    case 1: return "Walking";
    case 2: return "Socializing";
    case 3: return "Presenting";
    default: return "";
  }
}

void Context(int idx) {
  selContext = idx;
  playBgSound();
}

void Streams(int idx) {
  selStream = idx;
  loadStream("ExampleData_" + (idx + 1) + ".json");
}

void EventTypes(float[] values) {
  for (int i = 0; i < values.length; i++) {
    if (values[i] == 1.0) {
      eventTypeFilters[i] = true;
    } else {
      eventTypeFilters[i] = false;
    }
  }
}

void loadStream(String filename) {
  server.purgeTasksAndCancel();
  if (selStream != -1) server.loadAndScheduleJSONData(loadJSONArray(filename));
}

void playBgSound() {
  if (bgPlayer != null) bgPlayer.kill();
  if (bgSounds.get(getContextName()) != null) { // check if none is selected
    bgPlayer = getSamplePlayer(bgSounds.get(getContextName()));
    bgPlayer.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
    masterGain.addInput(bgPlayer);
  }
}

boolean shouldRender(Notification noti) {
  switch(noti.getType()) {
    case Tweet: return eventTypeFilters[0];
    case Email: return eventTypeFilters[1];
    case TextMessage: return eventTypeFilters[2];
    case PhoneCall: return eventTypeFilters[3];
    case VoiceMail: return eventTypeFilters[4];
    default: return false;
  }
}

void draw() {
  background(20);

  Notification noti = queue.poll();
  if (noti != null && shouldRender(noti)) {
    notiGain.setGain(defaultNotiVol);
    beepGain.setGain(defaultVmVol);
    lp.setFrequency(48000);
    switch (selContext) {
      case 0: // working out
        if (noti.getPriorityLevel() >= 2) notiGain.setGain(defaultNotiVol + 0.15);
        break;
      case 1: // walking
        if (noti.getPriorityLevel() < 4) notiGain.setGain(defaultNotiVol - 0.2);
        break;
      case 2: // socializing
        if (noti.getPriorityLevel() < 4) {
          lp.setFrequency(300);
          notiGain.setGain(defaultNotiVol + 0.1);
        }
        beepGain.setGain(0);
        break;
      case 3: // presenting
        if (noti.getPriorityLevel() == 4) {
          notiGain.setGain(0.2);
          SamplePlayer player = getSamplePlayer("vibrate.wav", true);
          notiGain.addInput(player);
        } else {
          notiGain.setGain(0);
          beepGain.setGain(0);
        }
        break;
      default: // the -1 case
        notiGain.setGain(0);
        beepGain.setGain(0);
        break;
    }
    if (selContext != 3) {
      switch (noti.getType()) {
        case Tweet:
          if (noti.getPriorityLevel() == 4) {
            tts.textToSpeechAudio("New tweet by " + noti.getSender() + ": " + noti.getMessage());
          } else {
            SamplePlayer player = getSamplePlayer("tweet.wav", true);
            lp.addInput(player);
          }
          break;
        case Email:
          if (noti.getPriorityLevel() == 4) {
            tts.textToSpeechAudio("Urgent email from " + noti.getSender() + ": " + noti.getMessage());
          } else {
            SamplePlayer player = getSamplePlayer("email.wav", true);
            if (noti.getContentSummary() == 1) player.getPitchUGen().setValue(0.8);
            if (noti.getContentSummary() == 3) player.getPitchUGen().setValue(1.2);
            lp.addInput(player);
          }
          break;
        case TextMessage:
          if (noti.getPriorityLevel() == 4) {
            tts.textToSpeechAudio("Text message from " + noti.getSender() + ": " + noti.getMessage());
          } else {
            SamplePlayer player = getSamplePlayer("text.wav", true);
            if (noti.getContentSummary() == 1) player.getPitchUGen().setValue(0.8);
            if (noti.getContentSummary() == 3) player.getPitchUGen().setValue(1.2);
            lp.addInput(player);
          }
          break;
        case PhoneCall:
          if (noti.getPriorityLevel() == 4) {
            tts.textToSpeechAudio("Incoming call from " + noti.getSender() + ": " + noti.getMessage());
          } else {
            SamplePlayer player = getSamplePlayer("phone.wav", true);
            lp.addInput(player);
          }
          break;
        case VoiceMail:
          // statement to determine if beep is pitched up/down
          if (noti.getContentSummary() == 1) vmBeep = new WavePlayer(ac, 500.0, Buffer.SINE);
          else if (noti.getContentSummary() == 3) vmBeep = new WavePlayer(ac, 650.0, Buffer.SINE);
          else vmBeep = new WavePlayer(ac, 600.0, Buffer.SINE);
          beepGain.addInput(vmBeep);
          timer.schedule(new TimerTask() {
            public void run() {
              beepGain.clearInputConnections();
            }
          }, vmBeepLength);
          tts.textToSpeechAudio("Voicemail from " + noti.getSender() + ": " + noti.getMessage());
          break;
      }
    }
  }
}
