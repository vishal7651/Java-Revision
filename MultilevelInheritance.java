class A{
    int x=10;
    int y =20;
}
class B extends A{
    int z = x+y;
}

class C extends B{
    void sum(){
     System.out.println("The addition of x and y is : " +z);
    }
}

public class MultilevelInheritance {
    public static void main(String[] args) {
        
    
    C c = new C();
    c.sum();
    }
}
