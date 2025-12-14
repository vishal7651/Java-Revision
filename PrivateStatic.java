class Fun{
    private static int x=10;

    void f1(){
        System.out.println("X is access using f1 function and the value of x is:"+x);
    }
}

public class PrivateStatic {
    public static void main(String[] args) {
        Fun f1 = new Fun();
        f1.f1();
    }
}
