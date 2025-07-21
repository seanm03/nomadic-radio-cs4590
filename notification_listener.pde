// This is the interface you'll need to implement, and register
// your implementation with the NotificationServer in order to
// receive notifications
interface NotificationListener {
  void notificationReceived(Notification notification);
}
