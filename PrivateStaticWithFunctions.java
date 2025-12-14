class A{
    int x;
    static int y;

    void f1(){
        y=22;
    }

    void f3(){
        y=45;
    }

    void f2(){
System.out.println(y);    }
    

}


public class PrivateStaticWithFunctions {
    public static void main(String[] args) {
        A a1= new A();
        A a2= new A();

        a1.f1();
        a2.f3();
        a2.f2();
    }
}
