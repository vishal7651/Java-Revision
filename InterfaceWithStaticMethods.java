interface I1{
    void h1();

    default void d1(){
        h2();
        System.out.println("Default Function ");

    }
    private void h2(){
        System.out.println("Static Function ");
    }

}

class Child implements I1 {

    public void h1(){
        System.out.println("h1 is called");
    }

    
}

public class InterfaceWithStaticMethods extends Child{
    public static void main(String[] args) {
        InterfaceWithStaticMethods i = new InterfaceWithStaticMethods();
        i.h1();
        i.d1();
    }
}
