class Parent {
    int x = 10;
}

class Child extends Parent {
    int x = 20;
}

public class VariableHiding {
    public static void main(String[] args) {
        Parent p = new Child();
        System.out.println(p.x);
    }
}
