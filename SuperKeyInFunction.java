class Parent {
    void show() {
        System.out.println("Show method in Parent class");
    }
}

class Child extends Parent {
    void show() {
        super.show(); // calls Parent's show()
        System.out.println("Show method in Child class");
    }
}

public class SuperKeyInFunction {
    public static void main(String[] args) {
        Child c = new Child();
        c.show();
    }
}
