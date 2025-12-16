interface A{
    default void show(){
System.out.println("Show Method Call which present in A ");

    };

}

interface B{
default void show(){
System.out.println("Show Method Call which present in B ");

};
}

class C implements A,B{
    @Override
    public void show(){
        A.super.show();     //  It choose A 

        B.super.show();     // It choose B
    }
    
}

public class MultipleInheritanceUsingInterface {
    public static void main(String[] args) {
        
    
    C c = new C();
 c.show();
    }
}
