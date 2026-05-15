import java.util.Scanner;

class Account {
    int bal;
    Account(int b1){
        this.bal=b1;
    }

boolean isSufficient(int w){
    if(bal>w){
        return true;
    }else{
        return false;
    }
}
void withdraw(int amt, String g1)
{
    bal=bal-amt;
    System.out.println("Transaction Successfull for the "+g1);
    System.out.println("Current balance for "+g1+"is : "+bal);
}
}

class Customer implements Runnable{
    String m1;
    Account x1;

    Customer(Account j1, String h1){
        this.x1=j1;
        this.m1=h1;
    }
    @Override
    public void run() {
        Scanner sc = new Scanner(System.in);
        synchronized(x1){
        System.out.println("Enter Amount to withdraw for "+m1);
        int amt=sc.nextInt();
        
        if(x1.isSufficient(amt)){
            x1.withdraw(amt, m1);
        }else{
            System.out.println("Insufficient balance for "+m1);
        }
    }
}
}
public class ThreadSyn {
    public static void main(String[] args) {
        Account a1 = new Account(5000);
        Customer c1 = new Customer(a1, "Vishal");
        Customer c2 = new Customer(a1, "Renuka");
        Thread t1 = new Thread(c1);
        Thread t2 = new Thread(c2);

        t1.start();
        t2.start();

    }
    
}
