// This is example code that shows how you might use a PriorityQueue
// to enqueue notification events. The code defines a custom
// comparator so that the queue is ordered by the priority field
// in the notifications.
import beads.*;
import org.jaudiolibs.beads.*;
import java.util.*;

// Define a custom Comparator class for notifications, based on
// their priority.
Comparator<Notification> priorityComparator = new Comparator<Notification>() {
  public int compare(Notification n1, Notification n2) {
    return min(n1.getPriorityLevel(), n2.getPriorityLevel());
  }
};

// Create a PriorityQueue to hold notifications, and which sets queue
// order based on the above comparator.
PriorityQueue<Notification> queue = new PriorityQueue<Notification>(10, priorityComparator);

// This just shows how you might create a NotificationListener that
// queues notifications rather than sonifying them directly.
class QueuingListener implements NotificationListener {  
  //this method must be implemented to receive notifications
  public void notificationReceived(Notification notification) {
    // add this notification to the priority queue
    queue.add(notification);
  }
}

// Finally, if you're using this pattern, you might have code in your draw() function
// that checks to see if there's anything in the queue and, if so, sonifies the top
// item.  Note that draw() here is commented out, since we don't want it to conflict
// with the one defined in the project_demo tab.

//void draw() {  
//  // check to see if events are in the queue, if so sonify them
//  notification = queue.poll();
//  
//  if (notification != null) {
//    // sonify based on type, priority, queue.size(), etc.
//  }
//}
