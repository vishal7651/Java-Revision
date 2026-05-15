class Sharedresource{
    synchronized void display(){
        System.out.println(Thread.currentThread().getName() + " Aquired Lock ");
        try{
            Thread.sleep(1000);
        }catch(InterruptedException e){
            e.printStackTrace();
        }
        System.out.println(Thread.currentThread().getName() + " Released Lock ");
    }
}

class MyThread extends Thread{
    Sharedresource sharedresource;

    MyThread(Sharedresource sharedresource){
        this.sharedresource=sharedresource;
    }

   public void run(){
    sharedresource.display();
   }


}

public class ThreadState {
    public static void main(String[] args) throws Exception {
        Sharedresource sharedresource = new Sharedresource();
         MyThread t1 = new MyThread(sharedresource);
    MyThread t2 = new MyThread(sharedresource);

        //New State
    System.out.println("1. The state of t1 is : "+t1.getState());

    t1.start();

    Thread.sleep(100);

    // Runnable or Running
    t2.start();

    System.out.println("2. State of t1 is : "+t1.getState());
    System.out.println("3. State of t2 is : "+t2.getState());

    Thread waitingThread = new Thread(()->{
        try{
            t1.join();
        }catch(InterruptedException e){
            e.printStackTrace();
        }
    });
    waitingThread.start();
    Thread.sleep(100);
    System.out.println("4. State of Wating Thread is : "+waitingThread.getState());

    t1.join();
    t2.join();

    System.out.println("5. State of t1 Thread is : "+t1.getState());
    System.out.println("6. State of t2 Thread is : "+t2.getState());



    }
    
}
