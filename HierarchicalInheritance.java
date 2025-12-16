class A{
      int x=20;
    int y=40;

    void show(){
        System.out.println("In the A class");
    }
}
class B extends A{
    void multiply(){
        System.out.println("In the B class and the multiplication is : "+x*y);
    }
}
class C extends A{
    void sum(){
        System.out.println("In the C class and the sum is : " +(x+y));
    }
}


public class HierarchicalInheritance {
    public static void main(String[] args) {
        
    
  B b = new B();

  C c = new C();

  c.sum();
  b.multiply();
  c.sum();
  c.show();

    }

}
