class A {
    int x = 10;
    int y = 20;
    int z = x + y;

    void show() {
        System.out.println("In the Parent class");
    }

}

class B extends A {
    void sum() {
        System.out.println("The Sum of x and Y is : "  +z);
    }

    void show() {
        System.out.println("In the child class");
    }
}

public class SingleInheritance {
    public static void main(String[] args) {
        B b = new B();      //It calls methods in B class
        A b1 = new B();     //It calls methods in B class   and   This is Runtime Polymorphism
        A a = new A();  //It calls methods in A class

        b.sum();
        b1.show();
        a.show();
        b.show();
        

    }
}
