class A{
    A(){
        System.out.println("A constructor called...");
    }
    A(int x){
        System.out.println("A constructor called with arguments and the value of x is :" +x);
    }
    
}
class B extends A{
    B(){
        super();
        System.out.println("B Constructor called...");
        
    }
    B(int y){
        super(y);
    }
  

}

public class ParentChileConstructor {
    public static void main(String[] args) {
        B b = new B();
        B b1 = new B(10);
    }
}
