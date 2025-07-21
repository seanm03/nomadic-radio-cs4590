// The NotificationServer loads up a JSON representation of a
// set of notifications and schedules these for dispatch using
// a timer. Once you've loaded a set of notifications these will
// stay loaded until completed.  You can, however, use 
// purgeTasksAndCancel() to delete any scheduled tasks.
//
// The common pattern for using this code is:
// 1. Instantiate a NotificationServer
// 2. Register an implementation of NotificationListener to
//    receive notifications as they are dispatched
// 3. Load a set of JSON data to start the server running,
//    via loadAndScheduleJSONData().
// 4. If you need to stop and load a different set of JSON
//    data, call purgeTasksAndCancel() and then load new
//    data via loadAndScheduleJSONData() again.

import java.util.Calendar;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

class NotificationServer {
  Timer timer;
  Calendar calendar;
  private ArrayList<NotificationListener> listeners;

  public NotificationServer() {
    timer = new Timer();
    listeners = new ArrayList<NotificationListener>();
    calendar = Calendar.getInstance();
  }
  
  // This is a convenience method that loads up JSON data
  // and schedules it.
  public void loadAndScheduleJSONData(JSONArray values) {
    ArrayList<Notification> notifications = getNotificationDataFromJSON(values);
    for (int i = 0; i < notifications.size(); i++) {
      this.scheduleTask(notifications.get(i));
    }
  }
  
  // Return an ArrayList of Notifications from JSON data. This
  // method does not schedule the notifications however.
  public ArrayList<Notification> getNotificationDataFromJSON(JSONArray values) {
    ArrayList<Notification> notifications = new ArrayList<Notification>();
    for (int i = 0; i < values.size(); i++) {
      notifications.add(new Notification(values.getJSONObject(i)));
    }
    return notifications;
  }

  // Schedule a single notification for execution
  public void scheduleTask(Notification notification) {
    timer.schedule(new NotificationTask(this, notification), notification.getTimestamp());
  }
  
  // Clears out any unprocessed tasks and cancels the timer. Note
  // that any audio already queued (such as speech) will continue
  // until played.
  public void purgeTasksAndCancel() {
    timer.cancel();
    timer = new Timer();
  }
  
  // Register a NotificationListener with this server; the
  // NotificationListener will be called whenever a
  // notification is delivered.
  public void addListener(NotificationListener listenerToAdd) {
    listeners.add(listenerToAdd);
  }
  
  // Remove the first occurrence of the specified listener
  public void removeListener(NotificationListener listenerToRemove) {
    listeners.remove(listenerToRemove);
  }
  
  // Remove ALL registered listeners
  public void removeAllListeners() {
    listeners.clear();
  }
  
  // Notify any registered listeners
  public void notifyListeners(Notification notification) {
    println(notification.toString());
    for (int i=0; i < listeners.size(); i++) {
      if (listeners.get(i) != null) {
        listeners.get(i).notificationReceived(notification);
      }
    }
  }
  
  // Helper class that lets us use the Timer to do notifications
  class NotificationTask extends TimerTask {  
    NotificationServer server;
    Notification notification;
    
    public NotificationTask(NotificationServer server, Notification notification) {
      super();
      this.server = server;
      this.notification = notification;
    }
    
    public void run() {
      server.notifyListeners(notification);
    }
  }
}
